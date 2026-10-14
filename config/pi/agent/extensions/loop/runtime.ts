import {
	execFile,
	execFileSync,
	spawn,
	type SpawnOptions,
} from 'node:child_process'
import {randomUUID} from 'node:crypto'
import {closeSync, existsSync, openSync} from 'node:fs'
import {
	appendFile,
	mkdir,
	open,
	readdir,
	readFile,
	rename,
	rm,
	rmdir,
	unlink,
} from 'node:fs/promises'
import {constants as osConstants} from 'node:os'
import {basename, join} from 'node:path'
import {withoutPaneIdentity} from '../lib/pane-identity.ts'
import {
	FILES,
	readOptional,
	readStateFile,
	sessionDirectory,
	truncateLog,
	writeAtomic,
	writeStateFile,
	type AttemptRecord,
	type DailySchedule,
	type LoopConfig,
	type LoopSchedule,
	type LoopStateFile,
	type LoopStatus,
} from './core.ts'
import {
	fallbackMessage,
	inboxPaths,
	MAX_ERROR_BYTES,
	reportId,
	truncateBytes,
	validateOwnerMessage,
	writeInboxMessage,
	type LoopInboxMessage,
} from './inbox.ts'
import {recordedDeliveries, type Submission} from './receiver.ts'

export const TERM_GRACE_MS = 10_000
export const KILL_WAIT_MS = 5_000
const MAX_TIMER_MS = 30_000
const PS_ARGS = ['-A', '-o', 'pid=', '-o', 'lstart=']
const PS_MAX_BUFFER = 16 * 1024 * 1024
const REGISTRY = Symbol.for('pi-loop.runtime')

// --- Scheduling ---

export function nextDailyRun(
	schedule: DailySchedule,
	now: number,
): number | undefined {
	const base = new Date(now)
	for (let offset = 0; offset <= 7; offset += 1) {
		const candidate = new Date(
			base.getFullYear(),
			base.getMonth(),
			base.getDate() + offset,
			schedule.hour,
			schedule.minute,
		)
		// A local time inside a daylight-saving gap is normalized to another
		// hour; skip that day instead of running at the wrong time.
		if (
			candidate.getHours() !== schedule.hour ||
			candidate.getMinutes() !== schedule.minute
		)
			continue
		if (candidate.getTime() > now) return candidate.getTime()
	}
	return undefined
}

/** Runs never overlap and missed ticks are skipped, not replayed. */
export function nextRunAfter(
	schedule: LoopSchedule,
	startedAt: number,
	now: number,
): number | undefined {
	if (schedule.kind === 'daily') return nextDailyRun(schedule, now)
	const due = startedAt + schedule.intervalMs
	return due > now ? due : now + schedule.intervalMs
}

/**
 * Waking at least every 30 s and comparing the wall clock keeps a due run
 * from waiting a whole extra interval after system sleep, while a short
 * interval still fires at its own time instead of the next 30 s tick.
 */
export function timerDelay(
	dueTimes: Iterable<number>,
	now: number,
): number | undefined {
	let earliest: number | undefined
	for (const due of dueTimes)
		earliest = earliest === undefined ? due : Math.min(earliest, due)
	if (earliest === undefined) return undefined
	return Math.min(MAX_TIMER_MS, Math.max(0, earliest - now))
}

// --- Process identity ---

/**
 * The child must be a direct child of the owner so that its parent watch
 * sees the owner die. A compiled Bun binary reports a virtual entrypoint in
 * argv[1]; passing it again would become an extra prompt argument.
 */
export function piInvocation(
	execPath = process.execPath,
	entry: string | undefined = process.argv[1],
	isFile: (path: string) => boolean = existsSync,
): string[] | undefined {
	if (entry?.startsWith('/$bunfs/')) return [execPath]
	const runtime = basename(execPath).toLowerCase()
	if ((runtime === 'node' || runtime === 'bun') && entry && isFile(entry))
		return [execPath, entry]
	return undefined
}

export type ProcessTable = Map<number, string>
export type Liveness = 'alive' | 'gone' | 'unknown'

export function normalizeLstart(value: string): string {
	return value.trim().replace(/\s+/g, ' ')
}

export function parseProcessTable(stdout: string): ProcessTable | undefined {
	const table: ProcessTable = new Map()
	for (const line of stdout.split('\n')) {
		const match = line.trim().match(/^(\d+)\s+(\S.*)$/)
		if (match) table.set(Number(match[1]), normalizeLstart(match[2]))
	}
	return table.size > 0 ? table : undefined
}

// lstart is printed in local time; a fixed zone and locale keep two
// processes with different TZ settings from disagreeing about one process.
const psEnv = () => ({...process.env, LC_ALL: 'C', TZ: 'UTC'})

/**
 * A full snapshot, never `ps -p`: a targeted query for a dead PID exits 1
 * with empty output, which is indistinguishable from a failed command.
 */
export function readProcessTable(): Promise<ProcessTable | undefined> {
	return new Promise((resolve) => {
		execFile(
			'ps',
			PS_ARGS,
			{env: psEnv(), maxBuffer: PS_MAX_BUFFER},
			(error, stdout) => resolve(error ? undefined : parseProcessTable(stdout)),
		)
	})
}

export function readProcessTableSync(): ProcessTable | undefined {
	try {
		return parseProcessTable(
			execFileSync('ps', PS_ARGS, {
				env: psEnv(),
				encoding: 'utf8',
				maxBuffer: PS_MAX_BUFFER,
			}),
		)
	} catch {
		return undefined
	}
}

export function classifyProcess(
	table: ProcessTable | undefined,
	pid: number | null | undefined,
	lstart: string | null | undefined,
	self = process.pid,
): Liveness {
	// A real snapshot always lists the process that took it.
	if (!table || !table.has(self) || !pid || !lstart) return 'unknown'
	const current = table.get(pid)
	if (current === undefined) return 'gone'
	return current === normalizeLstart(lstart) ? 'alive' : 'gone'
}

// --- Shared registry ---

export class Mutex {
	private tail: Promise<unknown> = Promise.resolve()

	run<T>(fn: () => Promise<T> | T): Promise<T> {
		const result = this.tail.then(fn)
		this.tail = result.catch(() => {})
		return result
	}
}

export interface ExitInfo {
	code: number | null
	signal: NodeJS.Signals | null
	spawnError?: string
}

export interface RunRecord {
	iteration: number
	startedAt: number
	pid?: number
	launching: Promise<void>
	exited: Promise<ExitInfo>
	exit?: ExitInfo
	finalization?: Promise<void>
}

export interface LoopEntry {
	dir: string
	config: LoopConfig
	state: LoopStatus
	nextRunAt?: number
	// Guards state transitions only, never a whole run, so a stop can always
	// interrupt a running task.
	mutex: Mutex
	// Serializes state.json read-modify-write cycles.
	writer: Mutex
	run?: RunRecord
	stillStopping: boolean
}

interface ChildLike {
	pid?: number
	once(
		event: 'exit',
		listener: (code: number | null, signal: NodeJS.Signals | null) => void,
	): unknown
	once(event: 'error', listener: (error: Error) => void): unknown
}

export interface RuntimeDeps {
	now(): number
	invocation: string[]
	extensionPath: string
	systemPrompt: string
	spawnChild(command: string, args: string[], options: SpawnOptions): ChildLike
	readProcessTable(): Promise<ProcessTable | undefined>
	kill(pid: number, signal: NodeJS.Signals): void
	termGraceMs: number
	killWaitMs: number
}

export interface RuntimeHooks {
	// Called whenever a report was published or loop state changed. Hooks belong
	// to the extension instance that registered them; it checks its own
	// generation before touching the UI.
	flush(): void
}

export interface SessionRuntime {
	sessionId: string
	root: string
	generation: number
	closing: boolean
	loops: Map<string, LoopEntry>
	timer?: NodeJS.Timeout
	lockToken?: string
	lockMutex: Mutex
	retirementId: string | null
	// Reactive sends that Pi may still hold in its private queue. Kept here
	// so /reload, which keeps that queue, also keeps this record.
	submissions: Submission[]
	seq: number
	sessionFile?: string
	deps: RuntimeDeps
	hooks: RuntimeHooks
}

export function registry(): Map<string, SessionRuntime> {
	const scope = globalThis as unknown as Record<symbol, unknown>
	scope[REGISTRY] ??= new Map<string, SessionRuntime>()
	return scope[REGISTRY] as Map<string, SessionRuntime>
}

export function defaultDeps(
	options: Pick<RuntimeDeps, 'invocation' | 'extensionPath' | 'systemPrompt'>,
): RuntimeDeps {
	return {
		...options,
		now: Date.now,
		spawnChild: (command, args, spawnOptions) =>
			spawn(command, args, spawnOptions),
		readProcessTable,
		kill: (pid, signal) => process.kill(pid, signal),
		termGraceMs: TERM_GRACE_MS,
		killWaitMs: KILL_WAIT_MS,
	}
}

export function newEntry(dir: string, config: LoopConfig): LoopEntry {
	return {
		dir,
		config,
		state: 'stopped',
		mutex: new Mutex(),
		writer: new Mutex(),
		stillStopping: false,
	}
}

function updateState(
	entry: LoopEntry,
	mutate: (state: LoopStateFile) => LoopStateFile,
): Promise<LoopStateFile> {
	return entry.writer.run(async () => {
		const next = mutate(await readStateFile(entry.dir))
		await writeStateFile(entry.dir, next)
		return next
	})
}

export function armTimer(rt: SessionRuntime): void {
	if (rt.timer) clearTimeout(rt.timer)
	rt.timer = undefined
	if (rt.closing) return
	const dueTimes: number[] = []
	for (const entry of rt.loops.values())
		if (entry.state === 'scheduled' && entry.nextRunAt !== undefined)
			dueTimes.push(entry.nextRunAt)
	const delay = timerDelay(dueTimes, rt.deps.now())
	if (delay === undefined) return
	rt.timer = setTimeout(() => startDueRuns(rt), delay)
	rt.timer.unref()
}

export function startDueRuns(rt: SessionRuntime): void {
	if (rt.closing) return
	const now = rt.deps.now()
	for (const entry of rt.loops.values())
		if (
			entry.state === 'scheduled' &&
			entry.nextRunAt !== undefined &&
			entry.nextRunAt <= now
		)
			void launchRun(rt, entry)
	armTimer(rt)
}

const iso = (time: number) => new Date(time).toISOString()

function runArgs(
	rt: SessionRuntime,
	entry: LoopEntry,
	iteration: number,
	hasLatest: boolean,
	claimed: string[],
): string[] {
	const {config} = entry
	const args = [
		'--no-session',
		'-p',
		'--extension',
		rt.deps.extensionPath,
		'--append-system-prompt',
		rt.deps.systemPrompt,
	]
	if (config.provider) args.push('--provider', config.provider)
	if (config.model) args.push('--model', config.model)
	if (config.thinking) args.push('--thinking', config.thinking)
	args.push(`@${join(entry.dir, FILES.prompt)}`)
	if (hasLatest) args.push(`@${join(entry.dir, FILES.latest)}`)
	for (const path of claimed) args.push(`@${path}`)
	args.push(
		`Execute the recurring task in the first attached file. This is iteration ${iteration}. When a previous report is attached, use it to avoid repeating unchanged items.${claimed.length > 0 ? ` The attached JSON files with "kind": "message" are instructions from the owner session for this run; apply them.` : ''} Produce the complete actionable report as your final response.`,
	)
	return args
}

async function hasContent(path: string): Promise<boolean> {
	return ((await readOptional(path)) ?? '').length > 0
}

/** Launch one run: intent on disk first, then spawn, then the identity. */
export async function launchRun(
	rt: SessionRuntime,
	entry: LoopEntry,
): Promise<void> {
	let releaseLaunch!: () => void
	const launching = new Promise<void>((resolve) => (releaseLaunch = resolve))
	try {
		await entry.mutex.run(async () => {
			if (entry.state !== 'scheduled' || rt.closing) return
			entry.state = 'running'
			entry.nextRunAt = undefined
			const startedAt = rt.deps.now()
			// The iteration comes from disk, so a crash can never reuse it.
			const state = await updateState(entry, (current) => {
				const iteration =
					Math.max(current.iteration, current.attempt?.iteration ?? 0) + 1
				return {
					...current,
					status: 'running',
					iteration,
					nextRunEpoch: undefined,
					lastStartedAt: iso(startedAt),
					ownerPid: process.pid,
					attempt: {
						iteration,
						phase: 'launching',
						pid: null,
						lstart: null,
						startedAt: iso(startedAt),
						finalized: false,
					},
				}
			})
			let settle!: (info: ExitInfo) => void
			const run: RunRecord = {
				iteration: state.iteration,
				startedAt,
				launching,
				exited: new Promise((resolve) => (settle = resolve)),
			}
			const finish = (info: ExitInfo) => {
				if (run.exit) return
				run.exit = info
				settle(info)
			}
			entry.run = run
			void run.exited.then(() => finalizeRun(rt, entry, run))
			try {
				await Promise.all(
					[FILES.commands, FILES.events, FILES.runtimeLog].map((name) =>
						truncateLog(join(entry.dir, name)),
					),
				)
				// Claim owner messages only after the launch intent is on disk,
				// so a crash cannot strand them under an unknown attempt.
				const claimed = await claimMessages(entry, run.iteration)
				const args = runArgs(
					rt,
					entry,
					run.iteration,
					await hasContent(join(entry.dir, FILES.latest)),
					claimed,
				)
				const result = resultPath(entry, run.iteration)
				await mkdir(join(entry.dir, FILES.results), {
					recursive: true,
					mode: 0o700,
				})
				await rm(result, {force: true})
				const stdout = openSync(join(entry.dir, FILES.stdout), 'w', 0o600)
				let stderr: number | undefined
				try {
					stderr = openSync(join(entry.dir, FILES.stderr), 'w', 0o600)
					const [command, ...prefix] = rt.deps.invocation
					const child = rt.deps.spawnChild(command, [...prefix, ...args], {
						cwd: entry.config.cwd,
						detached: true,
						stdio: ['ignore', stdout, stderr],
						env: {
							...withoutPaneIdentity(process.env),
							PI_LOOP_DIR: entry.dir,
							PI_LOOP_ID: entry.config.id,
							PI_LOOP_ITERATION: String(run.iteration),
							PI_LOOP_OWNER_SESSION_ID: rt.sessionId,
							PI_LOOP_PARENT_PID: String(process.pid),
							PI_LOOP_RESULT: result,
							PI_LOOP_INBOX: inboxPaths(rt.root, rt.sessionId)?.pending ?? '',
						},
					})
					child.once('exit', (code, signal) => finish({code, signal}))
					child.once('error', (error) =>
						finish({code: null, signal: null, spawnError: error.message}),
					)
					run.pid = child.pid
				} finally {
					closeSync(stdout)
					if (stderr !== undefined) closeSync(stderr)
				}
				await logRuntime(
					entry,
					`run_start iteration=${run.iteration} pid=${run.pid ?? 'none'}`,
				)
				if (run.pid !== undefined) {
					const pid = run.pid
					const lstart = (await rt.deps.readProcessTable())?.get(pid) ?? null
					await updateState(entry, (current) =>
						current.attempt?.iteration === run.iteration &&
						!current.attempt.finalized
							? {
									...current,
									attempt: {...current.attempt, phase: 'running', pid, lstart},
								}
							: current,
					)
				}
			} catch (error) {
				finish({
					code: null,
					signal: null,
					spawnError: error instanceof Error ? error.message : String(error),
				})
			}
		})
	} finally {
		releaseLaunch()
	}
}

function resultPath(entry: LoopEntry, iteration: number): string {
	return join(entry.dir, FILES.results, `${iteration}.json`)
}

async function jsonFiles(directory: string): Promise<string[]> {
	return (await readdir(directory).catch(() => [] as string[]))
		.filter((name) => name.endsWith('.json'))
		.sort()
}

/** Move queued owner messages into this iteration's claim, in order. */
async function claimMessages(
	entry: LoopEntry,
	iteration: number,
): Promise<string[]> {
	const inbox = join(entry.dir, FILES.inbox)
	const names = await jsonFiles(inbox)
	if (names.length === 0) return []
	const claim = join(entry.dir, FILES.claimed, String(iteration))
	await mkdir(claim, {recursive: true, mode: 0o700})
	const claimed: string[] = []
	for (const name of names) {
		try {
			await rename(join(inbox, name), join(claim, name))
			claimed.push(join(claim, name))
		} catch {}
	}
	return claimed
}

/** Claims of earlier iterations: the child never confirmed them. */
export async function needsReview(
	entry: LoopEntry,
): Promise<Array<{iteration: number; files: string[]}>> {
	const root = join(entry.dir, FILES.claimed)
	const running = entry.run && !entry.run.exit ? entry.run.iteration : undefined
	const claims: Array<{iteration: number; files: string[]}> = []
	for (const name of await readdir(root).catch(() => [] as string[])) {
		if (!/^\d+$/.test(name) || Number(name) === running) continue
		const files = await jsonFiles(join(root, name))
		if (files.length > 0) claims.push({iteration: Number(name), files})
	}
	return claims.sort((a, b) => a.iteration - b.iteration)
}

export interface RequeueOutcome {
	moved: number
	kept: string[]
}

/**
 * Put unconfirmed owner messages back for the next run. One rename per
 * file, inside the loop directory, so a crash leaves each message in
 * exactly one place. IDs are unique, so an existing target with the same
 * bytes is the same message; different bytes are kept and reported.
 */
export async function requeueMessages(
	entry: LoopEntry,
): Promise<RequeueOutcome> {
	return entry.mutex.run(async () => {
		const outcome: RequeueOutcome = {moved: 0, kept: []}
		const inbox = join(entry.dir, FILES.inbox)
		await mkdir(inbox, {recursive: true, mode: 0o700})
		for (const claim of await needsReview(entry)) {
			const directory = join(entry.dir, FILES.claimed, String(claim.iteration))
			for (const name of claim.files) {
				const source = join(directory, name)
				const content = await readFile(source, 'utf8').catch(() => undefined)
				if (content === undefined) continue
				let valid = false
				try {
					valid =
						typeof validateOwnerMessage(JSON.parse(content), name) !== 'string'
				} catch {}
				if (!valid) {
					outcome.kept.push(source)
					continue
				}
				const target = join(inbox, name)
				const existing = await readFile(target, 'utf8').catch(() => undefined)
				if (existing !== undefined) {
					if (existing === content) await unlink(source).catch(() => {})
					else outcome.kept.push(source)
					continue
				}
				try {
					await rename(source, target)
					outcome.moved += 1
				} catch (error) {
					if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error
				}
			}
			await rmdir(directory).catch(() => {})
		}
		return outcome
	})
}

/**
 * Publish once: the child's result when it wrote one, otherwise a failure.
 * A report that is already pending or recorded in the session is left
 * alone, so recovery after a crash never delivers it twice.
 */
async function publishReport(
	rt: SessionRuntime,
	entry: LoopEntry,
	fields: {
		iteration: number
		exitCode?: number
		error?: string
		durationSeconds?: number
		finishedAt: number
	},
): Promise<void> {
	const paths = inboxPaths(rt.root, rt.sessionId)
	if (!paths) return
	await mkdir(paths.pending, {recursive: true, mode: 0o700})
	await mkdir(paths.rejected, {recursive: true, mode: 0o700})
	const id = reportId(entry.config.id, fields.iteration)
	const target = join(paths.pending, `${id}.json`)
	if (existsSync(target)) return
	if ((await recordedDeliveries(rt.sessionFile)).ids.has(id)) return
	const pendingReview = (
		await jsonFiles(join(entry.dir, FILES.claimed, String(fields.iteration)))
	).length
	const result = resultPath(entry, fields.iteration)
	if (existsSync(result)) {
		if (pendingReview === 0) {
			await rename(result, target)
			return
		}
		// The run did not confirm its owner messages; say so on its report.
		const message = JSON.parse(
			await readFile(result, 'utf8'),
		) as LoopInboxMessage
		await writeInboxMessage(paths.pending, {
			...message,
			needsReview: pendingReview,
		})
		await unlink(result).catch(() => {})
		return
	}
	let error = fields.error
	if (error === undefined) {
		const stderr = (await readOptional(join(entry.dir, FILES.stderr))) ?? ''
		error = stderr.trim() === '' ? undefined : stderr.slice(-MAX_ERROR_BYTES)
	}
	await writeInboxMessage(
		paths.pending,
		fallbackMessage({
			loopId: entry.config.id,
			iteration: fields.iteration,
			ownerSessionId: rt.sessionId,
			exitCode: fields.exitCode,
			error:
				error === undefined ? undefined : truncateBytes(error, MAX_ERROR_BYTES),
			durationSeconds: fields.durationSeconds,
			createdAt: iso(fields.finishedAt),
			needsReview: pendingReview || undefined,
		}),
	)
}

export function exitCodeOf(exit: ExitInfo): number | undefined {
	if (exit.spawnError !== undefined) return undefined
	if (exit.code !== null) return exit.code
	if (exit.signal) {
		const number = osConstants.signals[exit.signal]
		return number === undefined ? undefined : 128 + number
	}
	return undefined
}

async function logRuntime(entry: LoopEntry, message: string): Promise<void> {
	await appendFile(
		join(entry.dir, FILES.runtimeLog),
		`${new Date().toISOString()} ${message}\n`,
		{encoding: 'utf8', mode: 0o600},
	).catch(() => {})
}

interface ReportFields {
	iteration: number
	startedAt: string
	finishedAt: string
	durationSeconds: number
	exitCode?: number
	error?: string
}

/** Same layout earlier versions wrote, so old reports and parsers still fit. */
export function formatReport(
	loopId: string,
	fields: ReportFields,
	stdout: string,
	stderr: string,
): string {
	let report = `# Pi loop ${loopId} — iteration ${fields.iteration}\n\n`
	report += `- Started: ${fields.startedAt}\n`
	report += `- Finished: ${fields.finishedAt}\n`
	report += `- Duration: ${fields.durationSeconds}s\n`
	report +=
		fields.exitCode !== undefined
			? `- Exit code: ${fields.exitCode}\n\n`
			: `- Error: ${fields.error ?? 'unknown'}\n\n`
	report += stdout
	if (stderr.length > 0) report += `\n\n## stderr\n\n${stderr}`
	return `${report}\n`
}

async function writeReport(
	entry: LoopEntry,
	fields: ReportFields,
): Promise<string> {
	const stdout = (await readOptional(join(entry.dir, FILES.stdout))) ?? ''
	const stderr = (await readOptional(join(entry.dir, FILES.stderr))) ?? ''
	const report = formatReport(entry.config.id, fields, stdout, stderr)
	await writeAtomic(join(entry.dir, FILES.latest), report)
	const runs = join(entry.dir, FILES.runs)
	await truncateLog(runs)
	await appendFile(runs, `${report}\n---\n\n`, {encoding: 'utf8', mode: 0o600})
	return report
}

async function settledWithin(run: RunRecord, ms: number): Promise<boolean> {
	if (run.exit) return true
	let timer: NodeJS.Timeout | undefined
	const timeout = new Promise<false>((resolve) => {
		timer = setTimeout(() => resolve(false), ms)
		timer.unref()
	})
	try {
		return await Promise.race([run.exited.then(() => true as const), timeout])
	} finally {
		clearTimeout(timer)
	}
}

/**
 * Exactly one finalization per run, shared by every extension instance:
 * the first caller creates it synchronously and later callers, for
 * example after /reload, join the same promise.
 */
export function finalizeRun(
	rt: SessionRuntime,
	entry: LoopEntry,
	run: RunRecord,
): Promise<void> {
	run.finalization ??= (async () => {
		await run.exited
		const exit = run.exit as ExitInfo
		const finishedAt = rt.deps.now()
		const exitCode = exitCodeOf(exit)
		const durationSeconds = Math.max(
			0,
			Math.round((finishedAt - run.startedAt) / 1000),
		)
		await writeReport(entry, {
			iteration: run.iteration,
			startedAt: iso(run.startedAt),
			finishedAt: iso(finishedAt),
			durationSeconds,
			exitCode,
			error: exit.spawnError,
		})
		await publishReport(rt, entry, {
			iteration: run.iteration,
			exitCode,
			error: exit.spawnError,
			durationSeconds,
			finishedAt,
		})
		await logRuntime(
			entry,
			`run_finish iteration=${run.iteration} exit=${exitCode ?? exit.spawnError ?? 'unknown'}`,
		)
		await updateState(entry, (current) => ({
			...current,
			lastFinishedAt: iso(finishedAt),
			lastExitCode: exitCode,
			lastDurationSeconds: durationSeconds,
			attempt:
				current.attempt?.iteration === run.iteration
					? {...current.attempt, phase: 'done', finalized: true}
					: current.attempt,
		}))
		await entry.mutex.run(async () => {
			if (entry.run === run) entry.run = undefined
			entry.stillStopping = false
			if (entry.state === 'running') {
				const next = nextRunAfter(
					entry.config.schedule,
					run.startedAt,
					rt.deps.now(),
				)
				entry.state = next === undefined || rt.closing ? 'stopped' : 'scheduled'
				entry.nextRunAt = entry.state === 'scheduled' ? next : undefined
			} else if (entry.state === 'stopping') {
				entry.state = 'stopped'
			}
			await updateState(entry, (current) => ({
				...current,
				status: entry.state,
				nextRunEpoch:
					entry.nextRunAt === undefined
						? undefined
						: Math.floor(entry.nextRunAt / 1000),
			}))
		})
		armTimer(rt)
		rt.hooks.flush()
	})()
	return run.finalization
}

function signalRun(
	rt: SessionRuntime,
	entry: LoopEntry,
	run: RunRecord,
	signal: NodeJS.Signals,
	group = false,
): void {
	// Node settles `exit` in the same callback that reaps the child, so an
	// unsettled run still owns its PID and its process group ID.
	if (entry.run !== run || run.exit || run.pid === undefined) return
	try {
		rt.deps.kill(group ? -run.pid : run.pid, signal)
	} catch {}
}

/** TERM lets Pi clean up its tracked tools; KILL reaches only our group. */
export async function stopLoop(
	rt: SessionRuntime,
	entry: LoopEntry,
): Promise<'stopped' | 'still-stopping'> {
	let run: RunRecord | undefined
	await entry.mutex.run(async () => {
		entry.nextRunAt = undefined
		if (entry.state === 'stopped') return
		if (!entry.run) {
			entry.state = 'stopped'
		} else {
			entry.state = 'stopping'
			run = entry.run
		}
		await updateState(entry, (current) => ({
			...current,
			status: entry.state,
			nextRunEpoch: undefined,
		}))
	})
	armTimer(rt)
	rt.hooks.flush()
	if (!run) return entry.stillStopping ? 'still-stopping' : 'stopped'
	await run.launching
	signalRun(rt, entry, run, 'SIGTERM')
	if (!(await settledWithin(run, rt.deps.termGraceMs))) {
		signalRun(rt, entry, run, 'SIGKILL', true)
		if (!(await settledWithin(run, rt.deps.killWaitMs))) {
			entry.stillStopping = true
			await logRuntime(entry, `still_stopping iteration=${run.iteration}`)
			return 'still-stopping'
		}
	}
	await finalizeRun(rt, entry, run)
	return 'stopped'
}

export async function scheduleLoop(
	rt: SessionRuntime,
	entry: LoopEntry,
): Promise<void> {
	await entry.mutex.run(async () => {
		// Starting or restarting a loop runs it once right away, whatever its
		// schedule; the schedule decides the runs after that one.
		const next = rt.deps.now()
		entry.state = 'scheduled'
		entry.nextRunAt = next
		await updateState(entry, (current) => ({
			...current,
			status: 'scheduled',
			ownerPid: process.pid,
			nextRunEpoch: Math.floor(next / 1000),
		}))
	})
	startDueRuns(rt)
	rt.hooks.flush()
}

// --- Reconciliation ---

export type Reconciliation = 'idle' | 'recovered' | 'alive' | 'uncertain'

async function readSelfRecord(
	dir: string,
	iteration: number,
): Promise<{pid?: number; lstart?: string | null} | undefined> {
	const content = await readOptional(
		join(dir, FILES.results, `${iteration}.child.json`),
	)
	if (!content) return undefined
	try {
		return JSON.parse(content) as {pid?: number; lstart?: string | null}
	} catch {
		return undefined
	}
}

async function finalizeRecovered(
	rt: SessionRuntime,
	entry: LoopEntry,
	attempt: AttemptRecord,
	reason: string,
): Promise<void> {
	const finishedAt = rt.deps.now()
	const durationSeconds = Math.max(
		0,
		Math.round((finishedAt - Date.parse(attempt.startedAt)) / 1000),
	)
	await writeReport(entry, {
		iteration: attempt.iteration,
		startedAt: attempt.startedAt,
		finishedAt: iso(finishedAt),
		durationSeconds,
		error: reason,
	})
	await publishReport(rt, entry, {
		iteration: attempt.iteration,
		error: reason,
		durationSeconds,
		finishedAt,
	})
	await logRuntime(
		entry,
		`run_recovered iteration=${attempt.iteration} reason=${reason}`,
	)
	await updateState(entry, (current) => ({
		...current,
		status: 'stopped',
		nextRunEpoch: undefined,
		lastFinishedAt: iso(finishedAt),
		lastExitCode: undefined,
		attempt:
			current.attempt?.iteration === attempt.iteration
				? {...current.attempt, phase: 'done', finalized: true}
				: current.attempt,
	}))
	rt.hooks.flush()
}

/**
 * Decide what an unfinalized attempt from an earlier runtime means. A
 * process that is merely absent from a good snapshot is gone; only a failed
 * inspection or a missing identity is unknown, and unknown is never dead.
 */
export async function reconcileLoop(
	rt: SessionRuntime,
	entry: LoopEntry,
	resolvedByUser = false,
): Promise<Reconciliation> {
	return entry.mutex.run(async () => {
		if (entry.run || entry.state !== 'stopped') return 'idle'
		const state = await readStateFile(entry.dir)
		const attempt = state.attempt
		if (!attempt || attempt.finalized) {
			if (state.status !== 'stopped')
				await updateState(entry, (current) => ({
					...current,
					status: 'stopped',
					nextRunEpoch: undefined,
				}))
			return 'idle'
		}
		let pid = attempt.phase === 'running' ? attempt.pid : null
		let lstart = attempt.phase === 'running' ? attempt.lstart : null
		if (!pid || !lstart) {
			const self = await readSelfRecord(entry.dir, attempt.iteration)
			pid = self?.pid ?? null
			lstart = self?.lstart ?? null
		}
		const liveness = classifyProcess(
			await rt.deps.readProcessTable(),
			pid,
			lstart,
		)
		if (liveness === 'alive') return 'alive'
		if (liveness === 'unknown' && !resolvedByUser) return 'uncertain'
		await finalizeRecovered(
			rt,
			entry,
			attempt,
			liveness === 'gone'
				? 'the owner Pi ended before this run finished'
				: 'outcome unknown: resolved by the user',
		)
		return 'recovered'
	})
}

// --- Session lock and lifecycle ---

export interface LockHolder {
	pid?: number
	token?: string
	startedAt?: string
}

function lockPath(rt: Pick<SessionRuntime, 'root' | 'sessionId'>): string {
	const directory = sessionDirectory(rt.root, rt.sessionId)
	if (!directory) throw new Error(`Invalid session ID: ${rt.sessionId}`)
	return join(directory, 'receiver.lock')
}

export async function readLockHolder(
	rt: Pick<SessionRuntime, 'root' | 'sessionId'>,
): Promise<LockHolder | undefined> {
	const content = await readOptional(lockPath(rt))
	if (!content) return undefined
	try {
		return JSON.parse(content) as LockHolder
	} catch {
		return {}
	}
}

/** Exclusive create only; a stale lock is never reclaimed automatically. */
export async function acquireLock(rt: SessionRuntime): Promise<boolean> {
	if (rt.lockToken) return true
	const path = lockPath(rt)
	await mkdir(join(path, '..'), {recursive: true, mode: 0o700})
	const token = randomUUID()
	try {
		const handle = await open(path, 'wx', 0o600)
		try {
			await handle.writeFile(
				JSON.stringify({
					pid: process.pid,
					token,
					startedAt: new Date().toISOString(),
				}),
			)
		} finally {
			await handle.close()
		}
	} catch {
		return false
	}
	rt.lockToken = token
	return true
}

async function releaseLock(rt: SessionRuntime): Promise<void> {
	const token = rt.lockToken
	rt.lockToken = undefined
	if (!token) return
	const holder = await readLockHolder(rt)
	if (holder?.token === token) await unlink(lockPath(rt)).catch(() => {})
}

export function lockDiagnostic(
	rt: Pick<SessionRuntime, 'root' | 'sessionId'>,
	holder: LockHolder | undefined,
): string {
	return `PID ${holder?.pid ?? 'unknown'} has held the loop inbox for this session since ${holder?.startedAt ?? 'an unknown time'}. If that process is not running, delete ${lockPath(rt)}.`
}

export type AttachResult = {rt: SessionRuntime; lock: boolean; adopted: boolean}

/**
 * Bind this extension instance to the session runtime. /reload keeps the
 * runtime as it is; a resume in the same process adopts a runtime that is
 * still retiring and cancels that retirement.
 */
export async function attachSession(options: {
	sessionId: string
	root: string
	reason: string
	deps: RuntimeDeps
	hooks: RuntimeHooks
	sessionFile?: string
}): Promise<AttachResult> {
	const runtimes = registry()
	let rt = runtimes.get(options.sessionId)
	if (rt && options.reason === 'reload') {
		rt.generation += 1
		rt.closing = false
		rt.deps = options.deps
		rt.hooks = options.hooks
		rt.sessionFile = options.sessionFile
		armTimer(rt)
		return {rt, lock: Boolean(rt.lockToken), adopted: false}
	}
	if (rt) {
		// Cancel the retirement before any await, so its continuation can no
		// longer delete this entry or release the lock that it now shares.
		rt.retirementId = null
		rt.generation += 1
		rt.closing = false
		rt.deps = options.deps
		rt.hooks = options.hooks
		rt.sessionFile = options.sessionFile
		const adopting = rt
		await adopting.lockMutex.run(async () => {
			if (adopting.lockToken) {
				const holder = await readLockHolder(adopting)
				if (holder?.token === adopting.lockToken) return
				adopting.lockToken = undefined
			}
			await acquireLock(adopting)
		})
		return {rt, lock: Boolean(rt.lockToken), adopted: true}
	}
	rt = {
		sessionId: options.sessionId,
		root: options.root,
		generation: 1,
		closing: false,
		loops: new Map(),
		lockMutex: new Mutex(),
		retirementId: null,
		submissions: [],
		seq: 0,
		sessionFile: options.sessionFile,
		deps: options.deps,
		hooks: options.hooks,
	}
	runtimes.set(options.sessionId, rt)
	const fresh = rt
	await fresh.lockMutex.run(() => acquireLock(fresh))
	return {rt, lock: Boolean(rt.lockToken), adopted: false}
}

/**
 * Invalidate this instance first. /reload keeps children, runs, and locks;
 * every other reason stops the loops and releases ownership only after all
 * of their writers have finished.
 */
export async function detachSession(
	rt: SessionRuntime,
	reason: string,
): Promise<void> {
	rt.generation += 1
	// An adoption during the awaits below bumps the generation again; then
	// this detach must not delete the runtime or release its lock.
	const detachedGeneration = rt.generation
	if (rt.timer) clearTimeout(rt.timer)
	rt.timer = undefined
	if (reason === 'reload') return
	rt.closing = true
	const entries = [...rt.loops.values()]
	await Promise.all(entries.map((entry) => stopLoop(rt, entry)))
	await Promise.allSettled(
		entries.flatMap((entry) =>
			entry.run && !entry.stillStopping
				? [entry.run.launching, entry.run.finalization ?? Promise.resolve()]
				: [],
		),
	)
	const retained = entries.filter((entry) => entry.stillStopping)
	if (retained.length === 0) {
		await rt.lockMutex.run(async () => {
			if (rt.generation !== detachedGeneration) return
			if (registry().get(rt.sessionId) === rt) registry().delete(rt.sessionId)
			await releaseLock(rt)
		})
		return
	}
	if (rt.generation !== detachedGeneration) return
	for (const [id, entry] of rt.loops)
		if (!entry.stillStopping) rt.loops.delete(id)
	const retirementId = randomUUID()
	rt.retirementId = retirementId
	const runs = retained.flatMap((entry) =>
		entry.run ? [finalizeRun(rt, entry, entry.run)] : [],
	)
	void (async () => {
		await Promise.allSettled(runs)
		await rt.lockMutex.run(async () => {
			if (rt.retirementId !== retirementId) return
			if (registry().get(rt.sessionId) === rt) registry().delete(rt.sessionId)
			await releaseLock(rt)
		})
	})()
}

export async function loadSessionLoops(
	rt: SessionRuntime,
	loops: Array<{dir: string; config: LoopConfig}>,
): Promise<Map<string, Reconciliation>> {
	const outcomes = new Map<string, Reconciliation>()
	for (const {dir, config} of loops) {
		if (config.ownerSessionId !== rt.sessionId) continue
		let entry = rt.loops.get(config.id)
		if (!entry) {
			entry = newEntry(dir, config)
			rt.loops.set(config.id, entry)
		}
		outcomes.set(config.id, await reconcileLoop(rt, entry))
	}
	return outcomes
}
