import assert from 'node:assert/strict'
import {execFile, spawn} from 'node:child_process'
import {randomUUID} from 'node:crypto'
import {EventEmitter} from 'node:events'
import {existsSync} from 'node:fs'
import {
	mkdir,
	mkdtemp,
	readdir,
	readFile,
	realpath,
	rm,
	writeFile,
} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import type {
	ExtensionAPI,
	ExtensionContext,
	TurnEndEvent,
} from '@earendil-works/pi-coding-agent'
import {executable, PiRpc, ScriptedModel} from '../lib/test-support.ts'
import {
	cardLines,
	legacyReportItem,
	parseReportHeader,
	type CardTools,
} from './card.ts'
import {
	BUDGET_BYTES,
	buildBatch,
	DIGEST_LIMIT,
	FRAMING,
	INBOX_CUSTOM_TYPE,
	inboxPaths,
	MAX_ERROR_BYTES,
	MAX_NOTE_BYTES,
	MAX_TEXT_BYTES,
	noteId,
	ownerMessageId,
	parseInboxId,
	parseSessionRecords,
	payloadBytes,
	renderContent,
	reportId,
	validateMessage,
	writeInboxMessage,
	type BatchOptions,
	type Delivery,
	type InboxDetails,
	type LoopInboxMessage,
	type LoopOwnerMessage,
} from './inbox.ts'
import {parseStartArgs} from './parse.ts'
import {Receiver} from './receiver.ts'
import {
	createNoteSender,
	ORPHANED_EXIT_CODE,
	parseParentPid,
	registerLoopChild,
} from './child.ts'
import {
	FILES,
	readStateFile,
	sessionDirectory,
	writeConfig,
	writePrivateFile,
	writeStateFile,
	type LoopConfig,
	type LoopSchedule,
	type LoopStateFile,
} from './core.ts'
import {PANE_IDENTITY_VARIABLES} from '../lib/pane-identity.ts'
import {
	armTimer,
	attachSession,
	classifyProcess,
	detachSession,
	exitCodeOf,
	formatReport,
	needsReview,
	newEntry,
	nextDailyRun,
	nextRunAfter,
	parseProcessTable,
	piInvocation,
	readLockHolder,
	readProcessTable,
	reconcileLoop,
	registry,
	requeueMessages,
	scheduleLoop,
	stopLoop,
	timerDelay,
	type LoopEntry,
	type ProcessTable,
	type RuntimeDeps,
	type SessionRuntime,
} from './runtime.ts'

const SECOND = 1000
const MINUTE = 60 * SECOND

async function waitUntil(
	predicate: () => boolean | Promise<boolean>,
	timeout = 10_000,
): Promise<void> {
	const deadline = Date.now() + timeout
	while (!(await predicate())) {
		if (Date.now() > deadline) throw new Error('Timed out waiting')
		await new Promise((resolve) => setTimeout(resolve, 10))
	}
}

// --- Pure helpers ---

test('the invocation never passes a compiled binary its virtual entrypoint', () => {
	const pi = '/nix/store/x-pi-1.1.0/libexec/pi/pi'
	assert.deepEqual(
		piInvocation(pi, '/$bunfs/root/pi', () => true),
		[pi],
	)
	assert.deepEqual(
		piInvocation('/usr/bin/node', '/opt/pi/cli.js', () => true),
		['/usr/bin/node', '/opt/pi/cli.js'],
	)
	assert.deepEqual(
		piInvocation('/opt/bun', '/opt/pi/cli.ts', () => true),
		['/opt/bun', '/opt/pi/cli.ts'],
	)
	assert.equal(
		piInvocation('/usr/bin/node', '/missing.js', () => false),
		undefined,
	)
	assert.equal(
		piInvocation('/usr/bin/node', '', () => true),
		undefined,
	)
	assert.equal(
		piInvocation('/opt/pi-wrapper', '/opt/pi/cli.js', () => true),
		undefined,
	)
})

test('interval runs keep their phase and skip missed ticks', () => {
	const schedule: LoopSchedule = {kind: 'interval', intervalMs: 45 * SECOND}
	assert.equal(nextRunAfter(schedule, 0, 10 * SECOND), 45 * SECOND)
	assert.equal(nextRunAfter(schedule, 0, 50 * SECOND), 95 * SECOND)
})

test('the timer wakes at the earliest due run, at most 30 s away', () => {
	assert.equal(timerDelay([], 0), undefined)
	assert.equal(timerDelay([45 * SECOND], 0), 30 * SECOND)
	assert.equal(timerDelay([45 * SECOND], 30 * SECOND), 15 * SECOND)
	assert.equal(timerDelay([5 * SECOND, 45 * SECOND], 0), 5 * SECOND)
	assert.equal(timerDelay([-MINUTE], 0), 0)
})

test('daily runs use the next local occurrence and skip DST gaps', () => {
	const original = process.env.TZ
	process.env.TZ = 'Europe/Amsterdam'
	try {
		const morning = new Date(2026, 9, 14, 8, 0).getTime()
		assert.equal(
			nextDailyRun({kind: 'daily', hour: 9, minute: 0}, morning),
			new Date(2026, 9, 14, 9, 0).getTime(),
		)
		assert.equal(
			nextDailyRun({kind: 'daily', hour: 7, minute: 30}, morning),
			new Date(2026, 9, 15, 7, 30).getTime(),
		)
		// 02:30 does not exist on 2026-03-29 in Amsterdam.
		const beforeGap = new Date(2026, 2, 29, 1, 0).getTime()
		assert.equal(
			nextDailyRun({kind: 'daily', hour: 2, minute: 30}, beforeGap),
			new Date(2026, 2, 30, 2, 30).getTime(),
		)
	} finally {
		if (original === undefined) delete process.env.TZ
		else process.env.TZ = original
	}
})

test('a process is alive, gone, or unknown from one full snapshot', () => {
	const self = process.pid
	const table = parseProcessTable(
		`  ${self} Tue Oct 14 09:00:00 2026\n  4242 Tue Oct  7 08:00:00 2026\n`,
	) as ProcessTable
	assert.equal(table.get(4242), 'Tue Oct 7 08:00:00 2026')
	assert.equal(
		classifyProcess(table, 4242, 'Tue Oct  7 08:00:00 2026'),
		'alive',
	)
	assert.equal(classifyProcess(table, 4242, 'Wed Oct  8 08:00:00 2026'), 'gone')
	assert.equal(classifyProcess(table, 777, 'Tue Oct  7 08:00:00 2026'), 'gone')
	assert.equal(classifyProcess(table, 4242, null), 'unknown')
	assert.equal(classifyProcess(undefined, 4242, 'x'), 'unknown')
	// A snapshot that lacks its own caller is not a real snapshot.
	assert.equal(classifyProcess(new Map([[4242, 'x']]), 4242, 'x'), 'unknown')
	assert.equal(parseProcessTable(''), undefined)
})

test('a reaped child is gone, not unknown', async () => {
	const child = spawn('sleep', ['1'], {stdio: 'ignore'})
	const pid = child.pid as number
	const lstart = (await readProcessTable())?.get(pid) ?? null
	assert.ok(lstart, 'the live child must be in the snapshot')
	assert.equal(classifyProcess(await readProcessTable(), pid, lstart), 'alive')
	await new Promise((resolve) => child.once('exit', resolve))
	assert.equal(classifyProcess(await readProcessTable(), pid, lstart), 'gone')
})

test('process identity does not depend on the caller time zone', async () => {
	const original = process.env.TZ
	try {
		process.env.TZ = 'America/New_York'
		const newYork = (await readProcessTable())?.get(process.pid)
		process.env.TZ = 'Asia/Tokyo'
		const tokyo = (await readProcessTable())?.get(process.pid)
		assert.ok(newYork)
		assert.equal(tokyo, newYork)
	} finally {
		if (original === undefined) delete process.env.TZ
		else process.env.TZ = original
	}
})

test('exit codes stay numeric or absent', () => {
	assert.equal(exitCodeOf({code: 3, signal: null}), 3)
	assert.equal(exitCodeOf({code: null, signal: 'SIGTERM'}), 143)
	assert.equal(
		exitCodeOf({code: null, signal: null, spawnError: 'ENOENT'}),
		undefined,
	)
})

test('reports keep the layout of earlier versions', () => {
	const fields = {
		iteration: 2,
		startedAt: 'A',
		finishedAt: 'B',
		durationSeconds: 3,
	}
	assert.equal(
		formatReport('id1', {...fields, exitCode: 0}, 'body', ''),
		'# Pi loop id1 — iteration 2\n\n- Started: A\n- Finished: B\n- Duration: 3s\n- Exit code: 0\n\nbody\n',
	)
	assert.equal(
		formatReport('id1', {...fields, error: 'spawn ENOENT'}, '', 'oops'),
		'# Pi loop id1 — iteration 2\n\n- Started: A\n- Finished: B\n- Duration: 3s\n- Error: spawn ENOENT\n\n\n\n## stderr\n\noops\n',
	)
})

test('session directories stay inside the inbox root', () => {
	const root = '/state'
	assert.equal(sessionDirectory(root, 'abc-1.2_3'), '/state/inboxes/abc-1.2_3')
	for (const bad of ['.', '..', '', 'a/b', '../x', 'a b', 'x'.repeat(129)])
		assert.equal(sessionDirectory(root, bad), undefined, bad)
})

test('the parent PID must be a plain positive integer above 1', () => {
	assert.equal(parseParentPid('1234'), 1234)
	for (const bad of [undefined, '', '1', '0', '-5', '12a', '1.5'])
		assert.equal(parseParentPid(bad), undefined, String(bad))
})

// --- Child hooks ---

const CHILD_GUARD = Symbol.for('pi-loop.child')

function fakePi(): ExtensionAPI {
	return {on: () => {}} as unknown as ExtensionAPI
}

class ExitCalled extends Error {
	readonly code: number
	constructor(code: number) {
		super(`exit ${code}`)
		this.code = code
	}
}

const throwingExit = (code: number): never => {
	throw new ExitCalled(code)
}

test('a child without an owner PID or with a dead owner exits before work', async () => {
	const dir = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-child-')))
	try {
		const scope = globalThis as unknown as Record<symbol, unknown>
		for (const env of [
			{PI_LOOP_DIR: dir},
			{PI_LOOP_DIR: dir, PI_LOOP_PARENT_PID: '1'},
			{PI_LOOP_DIR: dir, PI_LOOP_PARENT_PID: String(process.ppid + 100000)},
		]) {
			delete scope[CHILD_GUARD]
			assert.throws(
				() => registerLoopChild(fakePi(), env, throwingExit),
				(error) =>
					error instanceof ExitCalled && error.code === ORPHANED_EXIT_CODE,
			)
		}
		assert.equal(existsSync(join(dir, FILES.results)), false)
	} finally {
		delete (globalThis as unknown as Record<symbol, unknown>)[CHILD_GUARD]
		await rm(dir, {recursive: true, force: true})
	}
})

test('a child of a live owner writes its self-record once', async () => {
	const dir = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-child-')))
	const scope = globalThis as unknown as Record<symbol, unknown>
	delete scope[CHILD_GUARD]
	const env = {
		PI_LOOP_DIR: dir,
		PI_LOOP_PARENT_PID: String(process.ppid),
		PI_LOOP_ITERATION: '7',
	}
	const stop = registerLoopChild(fakePi(), env, throwingExit) as () => void
	try {
		const record = JSON.parse(
			await readFile(join(dir, FILES.results, '7.child.json'), 'utf8'),
		) as {pid: number; lstart: string}
		assert.equal(record.pid, process.pid)
		assert.equal(
			record.lstart,
			(await readProcessTable())?.get(process.pid) ?? null,
		)
		// A second load of the same extension registers nothing.
		assert.equal(registerLoopChild(fakePi(), env, throwingExit), undefined)
	} finally {
		stop()
		delete scope[CHILD_GUARD]
		await rm(dir, {recursive: true, force: true})
	}
})

// --- Runtime state machine with fake processes ---

class FakeChild extends EventEmitter {
	readonly pid: number | undefined
	constructor(pid: number | undefined) {
		super()
		this.pid = pid
	}
}

interface Harness {
	root: string
	rt: SessionRuntime
	children: FakeChild[]
	spawns: Array<{command: string; args: string[]; env: NodeJS.ProcessEnv}>
	signals: Array<[number, NodeJS.Signals]>
	flushes: number
	table: ProcessTable
	now: {value: number}
	makeLoop(schedule?: LoopSchedule): Promise<LoopEntry>
	close(): Promise<void>
}

let fakePid = 3_900_000

async function harness(
	overrides: Partial<RuntimeDeps> & {
		onSignal?: (
			pid: number,
			signal: NodeJS.Signals,
			children: FakeChild[],
		) => void
	} = {},
): Promise<Harness> {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-rt-')))
	const children: FakeChild[] = []
	const spawns: Harness['spawns'] = []
	const signals: Harness['signals'] = []
	const table: ProcessTable = new Map([[process.pid, 'self']])
	const now = {value: Date.parse('2026-10-14T08:00:00Z')}
	const state = {flushes: 0}
	const deps: RuntimeDeps = {
		now: () => now.value,
		invocation: ['/fake/pi'],
		extensionPath: '/fake/loop/index.ts',
		systemPrompt: 'unattended',
		spawnChild: (command, args, options) => {
			spawns.push({command, args, env: options.env ?? {}})
			const child = new FakeChild((fakePid += 1))
			children.push(child)
			table.set(child.pid as number, `start ${child.pid}`)
			return child
		},
		readProcessTable: async () => new Map(table),
		kill: (pid, signal) => {
			signals.push([pid, signal])
			overrides.onSignal?.(pid, signal, children)
		},
		termGraceMs: 50,
		killWaitMs: 50,
		...overrides,
	}
	const sessionId = `test-${randomUUID()}`
	const {rt} = await attachSession({
		sessionId,
		root,
		reason: 'startup',
		deps,
		hooks: {flush: () => (state.flushes += 1)},
	})
	const h: Harness = {
		root,
		rt,
		children,
		spawns,
		signals,
		get flushes() {
			return state.flushes
		},
		table,
		now,
		async makeLoop(schedule = {kind: 'interval', intervalMs: 45 * SECOND}) {
			const id = `loop${Math.random().toString(36).slice(2, 8)}`
			const dir = join(root, id)
			await mkdir(dir)
			const config: LoopConfig = {
				version: 3,
				runtime: 'in-process',
				id,
				prompt: 'check CI',
				schedule,
				cwd: root,
				createdAt: new Date(now.value).toISOString(),
				ownerSessionId: sessionId,
			}
			await writeConfig(dir, config)
			await writePrivateFile(join(dir, FILES.prompt), 'check CI\n')
			await writeStateFile(dir, {status: 'stopped', iteration: 0})
			const entry = newEntry(dir, config)
			rt.loops.set(id, entry)
			return entry
		},
		async close() {
			if (registry().get(sessionId) === rt) await detachSession(rt, 'quit')
			if (rt.timer) clearTimeout(rt.timer)
			await rm(root, {recursive: true, force: true})
		},
	}
	return h
}

const exitWith = (
	child: FakeChild,
	code: number | null,
	signal: NodeJS.Signals | null = null,
) => child.emit('exit', code, signal)

/** A loop that waits for a future run, as one does between two runs. */
function scheduleLater(h: Harness, entry: LoopEntry): void {
	entry.state = 'scheduled'
	entry.nextRunAt = h.now.value + 60 * MINUTE
}

test('a daily loop runs at once, then at its next daily time', async () => {
	const h = await harness()
	try {
		const schedule: LoopSchedule = {kind: 'daily', hour: 9, minute: 0}
		const entry = await h.makeLoop(schedule)
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		exitWith(h.children[0], 0)
		await waitUntil(() => entry.state === 'scheduled')
		assert.equal(entry.nextRunAt, nextDailyRun(schedule, h.now.value))
	} finally {
		await h.close()
	}
})

test('a run spawns the child directly with the loop environment', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		const [{command, args, env}] = h.spawns
		assert.equal(command, '/fake/pi')
		assert.deepEqual(args.slice(0, 6), [
			'--no-session',
			'-p',
			'--extension',
			'/fake/loop/index.ts',
			'--append-system-prompt',
			'unattended',
		])
		assert.equal(args.filter((arg) => arg.includes('$bunfs')).length, 0)
		assert.equal(env.PI_LOOP_PARENT_PID, String(process.pid))
		assert.equal(env.PI_LOOP_ITERATION, '1')
		assert.equal(env.PI_LOOP_DIR, entry.dir)
		await waitUntil(
			async () => (await readStateFile(entry.dir)).attempt?.phase === 'running',
		)
		const running = await readStateFile(entry.dir)
		assert.equal(running.attempt?.pid, h.children[0].pid)

		await writeFile(join(entry.dir, FILES.stdout), 'all green')
		exitWith(h.children[0], 0)
		await waitUntil(() => entry.state === 'scheduled')
		const done = await readStateFile(entry.dir)
		assert.equal(done.attempt?.finalized, true)
		assert.equal(done.lastExitCode, 0)
		assert.equal(done.status, 'scheduled')
		assert.equal(entry.nextRunAt, h.now.value + 45 * SECOND)
		assert.match(
			await readFile(join(entry.dir, FILES.latest), 'utf8'),
			/all green/,
		)
		assert.ok(h.flushes > 0)
		assert.deepEqual(h.signals, [])
	} finally {
		await h.close()
	}
})

test('a stop that races a natural exit sends no further signal and does not reschedule', async () => {
	const h = await harness({
		onSignal: (_pid, signal, children) => {
			if (signal === 'SIGTERM') exitWith(children[0], null, 'SIGTERM')
		},
	})
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		assert.equal(await stopLoop(h.rt, entry), 'stopped')
		assert.deepEqual(h.signals, [[h.children[0].pid, 'SIGTERM']])
		assert.equal(entry.state, 'stopped')
		assert.equal(entry.nextRunAt, undefined)
		const state = await readStateFile(entry.dir)
		assert.equal(state.status, 'stopped')
		assert.equal(state.lastExitCode, 143)
	} finally {
		await h.close()
	}
})

test('a stop during finalization still ends stopped', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		exitWith(h.children[0], 0)
		assert.equal(await stopLoop(h.rt, entry), 'stopped')
		assert.equal(entry.state, 'stopped')
		assert.equal((await readStateFile(entry.dir)).status, 'stopped')
		assert.deepEqual(h.signals, [])
	} finally {
		await h.close()
	}
})

test('stopping a loop with no run is immediate', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		scheduleLater(h, entry)
		assert.equal(await stopLoop(h.rt, entry), 'stopped')
		assert.equal(h.spawns.length, 0)
		assert.deepEqual(h.signals, [])
	} finally {
		await h.close()
	}
})

test('a running loop with a past due time arms no timer', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		entry.state = 'running'
		entry.nextRunAt = h.now.value - MINUTE
		armTimer(h.rt)
		assert.equal(h.rt.timer, undefined)
	} finally {
		await h.close()
	}
})

test('a TERM-ignoring child gets KILL on its group only, after the grace', async () => {
	const h = await harness({
		onSignal: (pid, signal, children) => {
			if (signal === 'SIGKILL' && pid === -(children[0].pid as number))
				exitWith(children[0], null, 'SIGKILL')
		},
	})
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		const pid = h.children[0].pid as number
		assert.equal(await stopLoop(h.rt, entry), 'stopped')
		assert.deepEqual(h.signals, [
			[pid, 'SIGTERM'],
			[-pid, 'SIGKILL'],
		])
		assert.equal(entry.state, 'stopped')
	} finally {
		await h.close()
	}
})

test('a child that survives KILL stays still stopping until it exits', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		assert.equal(await stopLoop(h.rt, entry), 'still-stopping')
		assert.equal(entry.stillStopping, true)
		assert.equal(entry.state, 'stopping')
		assert.equal(await reconcileLoop(h.rt, entry), 'idle')
		exitWith(h.children[0], null, 'SIGKILL')
		await waitUntil(() => entry.state === 'stopped')
		assert.equal(entry.stillStopping, false)
		assert.equal((await readStateFile(entry.dir)).attempt?.finalized, true)
	} finally {
		await h.close()
	}
})

test('a spawn error settles once, publishes a failure, and signals nothing', async () => {
	const h = await harness({
		spawnChild: () => {
			const child = new FakeChild(undefined)
			setImmediate(() =>
				child.emit('error', new Error('spawn /fake/pi ENOENT')),
			)
			return child
		},
	})
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(
			async () => (await readStateFile(entry.dir)).attempt?.finalized === true,
		)
		const report = await readFile(join(entry.dir, FILES.latest), 'utf8')
		assert.match(report, /- Error: spawn \/fake\/pi ENOENT/)
		assert.equal((await readStateFile(entry.dir)).lastExitCode, undefined)
		await stopLoop(h.rt, entry)
		assert.deepEqual(h.signals, [])
	} finally {
		await h.close()
	}
})

test('a deleted working directory fails the real spawn without a PID', async () => {
	const h = await harness({
		spawnChild: (command, args, options) => spawn(command, args, options),
		invocation: ['/bin/sh', '-c', 'exit 0'],
	})
	try {
		const entry = await h.makeLoop()
		entry.config.cwd = join(h.root, 'deleted')
		await scheduleLoop(h.rt, entry)
		await waitUntil(
			async () => (await readStateFile(entry.dir)).attempt?.finalized === true,
		)
		const state = await readStateFile(entry.dir)
		assert.equal(state.attempt?.pid, null)
		assert.equal(state.lastExitCode, undefined)
		assert.match(
			await readFile(join(entry.dir, FILES.latest), 'utf8'),
			/- Error: /,
		)
		await stopLoop(h.rt, entry)
		assert.deepEqual(h.signals, [])
	} finally {
		await h.close()
	}
})

test('a late identity write cannot undo a finalized attempt', async () => {
	let releaseTable!: () => void
	const tableGate = new Promise<void>((resolve) => (releaseTable = resolve))
	const h = await harness()
	h.rt.deps.readProcessTable = async () => {
		await tableGate
		return new Map(h.table)
	}
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		exitWith(h.children[0], 0)
		await waitUntil(
			async () => (await readStateFile(entry.dir)).attempt?.finalized === true,
		)
		releaseTable()
		await waitUntil(() => entry.state === 'scheduled')
		const state = await readStateFile(entry.dir)
		assert.equal(state.attempt?.finalized, true)
		assert.equal(state.attempt?.pid, null)
	} finally {
		await h.close()
	}
})

async function writeAttempt(
	entry: LoopEntry,
	attempt: Partial<NonNullable<LoopStateFile['attempt']>>,
): Promise<void> {
	await writeStateFile(entry.dir, {
		status: 'running',
		iteration: 4,
		attempt: {
			iteration: 4,
			phase: 'running',
			pid: null,
			lstart: null,
			startedAt: '2026-10-14T07:00:00.000Z',
			finalized: false,
			...attempt,
		},
	})
}

test('reconciliation tells alive, gone, and uncertain attempts apart', async () => {
	const h = await harness()
	try {
		const alive = await h.makeLoop()
		await writeAttempt(alive, {pid: 4001, lstart: 'boot 4001'})
		h.table.set(4001, 'boot 4001')
		assert.equal(await reconcileLoop(h.rt, alive), 'alive')

		const reused = await h.makeLoop()
		await writeAttempt(reused, {pid: 4002, lstart: 'old 4002'})
		h.table.set(4002, 'new 4002')
		assert.equal(await reconcileLoop(h.rt, reused), 'recovered')
		const recovered = await readStateFile(reused.dir)
		assert.equal(recovered.attempt?.finalized, true)
		assert.equal(recovered.status, 'stopped')
		assert.match(
			await readFile(join(reused.dir, FILES.latest), 'utf8'),
			/owner Pi ended before this run finished/,
		)

		const launching = await h.makeLoop()
		await writeAttempt(launching, {phase: 'launching'})
		await mkdir(join(launching.dir, FILES.results))
		await writeFile(
			join(launching.dir, FILES.results, '4.child.json'),
			JSON.stringify({pid: 4003, lstart: 'boot 4003'}),
		)
		assert.equal(await reconcileLoop(h.rt, launching), 'recovered')

		const uncertain = await h.makeLoop()
		await writeAttempt(uncertain, {phase: 'launching'})
		assert.equal(await reconcileLoop(h.rt, uncertain), 'uncertain')
		assert.equal((await readStateFile(uncertain.dir)).attempt?.finalized, false)
		assert.equal(await reconcileLoop(h.rt, uncertain, true), 'recovered')
		assert.match(
			await readFile(join(uncertain.dir, FILES.latest), 'utf8'),
			/resolved by the user/,
		)

		h.rt.deps.readProcessTable = async () => undefined
		const failedSnapshot = await h.makeLoop()
		await writeAttempt(failedSnapshot, {pid: 4004, lstart: 'boot 4004'})
		assert.equal(await reconcileLoop(h.rt, failedSnapshot), 'uncertain')
	} finally {
		await h.close()
	}
})

test('the next iteration always follows the attempt on disk', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await writeStateFile(entry.dir, {
			status: 'stopped',
			iteration: 2,
			attempt: {
				iteration: 6,
				phase: 'done',
				pid: 1,
				lstart: 'x',
				startedAt: 'x',
				finalized: true,
			},
		})
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		assert.equal(h.spawns[0].env.PI_LOOP_ITERATION, '7')
	} finally {
		await h.close()
	}
})

test('a quit releases the lock only after the loops finalized', async () => {
	const h = await harness({
		onSignal: (_pid, signal, children) => {
			if (signal === 'SIGTERM') exitWith(children[0], null, 'SIGTERM')
		},
	})
	const entry = await h.makeLoop()
	await scheduleLoop(h.rt, entry)
	await waitUntil(() => h.spawns.length === 1)
	await detachSession(h.rt, 'quit')
	assert.equal(registry().has(h.rt.sessionId), false)
	assert.equal(await readLockHolder(h.rt), undefined)
	assert.equal((await readStateFile(entry.dir)).attempt?.finalized, true)
	await h.close()
})

test('a resume adopts a retiring runtime and cancels its retirement', async () => {
	const h = await harness()
	try {
		const old = await h.makeLoop()
		await scheduleLoop(h.rt, old)
		await waitUntil(() => h.spawns.length === 1)
		await detachSession(h.rt, 'new')
		assert.equal(old.stillStopping, true)
		assert.equal(registry().get(h.rt.sessionId), h.rt)
		const lock = await readLockHolder(h.rt)
		assert.equal(lock?.token, h.rt.lockToken)

		const adopted = await attachSession({
			sessionId: h.rt.sessionId,
			root: h.root,
			reason: 'resume',
			deps: h.rt.deps,
			hooks: h.rt.hooks,
		})
		assert.equal(adopted.rt, h.rt)
		assert.equal(adopted.adopted, true)
		assert.equal(adopted.lock, true)
		const fresh = await h.makeLoop()
		scheduleLater(h, fresh)

		exitWith(h.children[0], null, 'SIGKILL')
		await waitUntil(() => old.state === 'stopped')
		await new Promise((resolve) => setTimeout(resolve, 50))
		assert.equal(registry().get(h.rt.sessionId), h.rt)
		assert.equal((await readLockHolder(h.rt))?.token, h.rt.lockToken)
		assert.equal(fresh.state, 'scheduled')
	} finally {
		await h.close()
	}
})

test('an adoption racing a lock release ends with exactly one owner', async () => {
	const h = await harness()
	try {
		const releasing = detachSession(h.rt, 'resume')
		const adopted = await attachSession({
			sessionId: h.rt.sessionId,
			root: h.root,
			reason: 'resume',
			deps: h.rt.deps,
			hooks: h.rt.hooks,
		})
		await releasing
		assert.equal(registry().get(h.rt.sessionId), adopted.rt)
		assert.equal(adopted.lock, true)
		assert.equal((await readLockHolder(h.rt))?.token, adopted.rt.lockToken)
	} finally {
		await h.close()
	}
})

test('a reload keeps the runtime, its runs, and its lock', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		const token = h.rt.lockToken
		await detachSession(h.rt, 'reload')
		const reloaded = await attachSession({
			sessionId: h.rt.sessionId,
			root: h.root,
			reason: 'reload',
			deps: h.rt.deps,
			hooks: h.rt.hooks,
		})
		assert.equal(reloaded.rt, h.rt)
		assert.equal(h.rt.lockToken, token)
		assert.equal(entry.state, 'running')
		exitWith(h.children[0], 0)
		await waitUntil(() => entry.state === 'scheduled')
	} finally {
		await h.close()
	}
})

test('a second runtime cannot take a held session lock', async () => {
	const h = await harness()
	try {
		const runtimes = registry()
		const holder = runtimes.get(h.rt.sessionId) as SessionRuntime
		runtimes.delete(h.rt.sessionId)
		const second = await attachSession({
			sessionId: h.rt.sessionId,
			root: h.root,
			reason: 'startup',
			deps: h.rt.deps,
			hooks: h.rt.hooks,
		})
		assert.equal(second.lock, false)
		runtimes.set(h.rt.sessionId, holder)
	} finally {
		await h.close()
	}
})

// --- Actual Pi integration ---

const LOOP_EXTENSION = fileURLToPath(new URL('./index.ts', import.meta.url))
const OWNER_ARGS = [
	'--no-extensions',
	'--no-context-files',
	'--no-skills',
	'--no-prompt-templates',
	'--no-themes',
	'--no-tools',
	'--no-approve',
	'--model',
	'scripted/test',
	'--extension',
	LOOP_EXTENSION,
]

interface PiFixture {
	root: string
	project: string
	state: string
	env: NodeJS.ProcessEnv
	// Processes a test started or found; cleanup signals only these, and
	// only while their start time still matches.
	recorded: Array<{pid: number; lstart: string}>
}

const PROBE_SOURCE = `export default function (pi) {
	pi.registerCommand('probe-reload', {handler: async (_args, ctx) => { await ctx.reload() }})
	pi.registerCommand('probe-new', {handler: async (_args, ctx) => { await ctx.newSession() }})
}
`

async function withPiFixture(
	modelsJson: string,
	run: (fixture: PiFixture) => Promise<void>,
): Promise<void> {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-it-')))
	const recorded: PiFixture['recorded'] = []
	try {
		const agent = join(root, 'agent')
		const project = join(root, 'project')
		const tmp = join(root, 'tmp')
		const state = join(root, 'state')
		await Promise.all([agent, project, tmp, state].map((dir) => mkdir(dir)))
		await writeFile(join(agent, 'models.json'), modelsJson)
		await writeFile(
			join(agent, 'settings.json'),
			JSON.stringify({retry: {enabled: false}}),
		)
		await writeFile(join(root, 'probe.ts'), PROBE_SOURCE)
		await run({
			root,
			project,
			state,
			recorded,
			env: {
				PATH: process.env.PATH ?? '',
				HOME: root,
				XDG_CONFIG_HOME: join(root, 'config'),
				XDG_STATE_HOME: join(root, 'xdg-state'),
				PI_CODING_AGENT_DIR: agent,
				PI_OFFLINE: '1',
				PI_SKIP_VERSION_CHECK: '1',
				PI_LOOP_STATE_DIR: state,
				TMPDIR: tmp,
			},
		})
	} finally {
		const table = await readProcessTable()
		for (const {pid, lstart} of recorded)
			if (classifyProcess(table, pid, lstart) === 'alive')
				try {
					process.kill(pid, 'SIGKILL')
				} catch {}
		await rm(root, {recursive: true, force: true})
	}
}

async function loopDir(state: string): Promise<string> {
	let dirs: string[] = []
	await waitUntil(async () => {
		dirs = (await readdir(state)).filter((name) => name !== 'inboxes')
		return dirs.length > 0
	}, 30_000)
	return join(state, dirs[0])
}

async function waitForState(
	dir: string,
	predicate: (state: LoopStateFile) => boolean,
	timeout = 60_000,
): Promise<LoopStateFile> {
	let state = await readStateFile(dir)
	await waitUntil(
		async () => predicate((state = await readStateFile(dir))),
		timeout,
	)
	return state
}

/** Everything a failing assertion needs to explain what the run did. */
async function loopDiagnostics(dir: string): Promise<string> {
	const read = (name: string) =>
		readFile(join(dir, name), 'utf8').catch(() => '(missing)')
	return [
		`state.json: ${await read(FILES.state)}`,
		`runtime.log: ${await read(FILES.runtimeLog)}`,
		`run.stderr: ${await read(FILES.stderr)}`,
		`run.stdout: ${await read(FILES.stdout)}`,
	].join('\n')
}

test(
	'actual pi runs a loop in a direct child and records its report',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{text: 'all green'},
			{text: 'noted'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {message: '/loop 30s check CI'})
					const dir = await loopDir(fixture.state)
					await waitForState(dir, (state) => state.attempt?.finalized === true)
					const latest = await readFile(join(dir, FILES.latest), 'utf8')
					assert.match(latest, /- Exit code: 0/)
					assert.match(latest, /all green/)
					const request = JSON.stringify(model.requests[0])
					assert.equal(request.includes('$bunfs'), false, request)
					assert.match(request, /Execute the recurring task/)
					assert.match(request, /check CI/)
					// Reactive by default: the report starts an owner turn.
					await waitUntil(() => model.requests.length === 2, 30_000)
					const owner = JSON.stringify(model.requests[1])
					assert.ok(owner.includes(FRAMING), owner)
					assert.match(owner, /all green/)
					await rpc.waitFor((record) => record.type === 'agent_settled')
					await rpc.send('prompt', {message: '/loop stop'})
					await waitForState(dir, (state) => state.status === 'stopped')
					const pending = join(
						fixture.state,
						'inboxes',
						JSON.parse(await readFile(join(dir, FILES.config), 'utf8'))
							.ownerSessionId,
						'pending',
					)
					await waitUntil(
						async () => (await readdir(pending)).length === 0,
						20_000,
					)
					assert.equal(await rpc.close(), 0)
					assert.equal(rpc.stderr, '')
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

interface ProcessRow {
	pid: number
	ppid: number
	command: string
}

function processRows(): Promise<ProcessRow[]> {
	return new Promise((resolve, reject) => {
		execFile(
			'ps',
			['-A', '-o', 'pid=', '-o', 'ppid=', '-o', 'command='],
			{env: {...process.env, LC_ALL: 'C'}, maxBuffer: 16 * 1024 * 1024},
			(error, stdout) => {
				if (error) return reject(error)
				resolve(
					stdout.split('\n').flatMap((line) => {
						const match = line.trim().match(/^(\d+)\s+(\d+)\s+(.*)$/)
						return match
							? [
									{
										pid: Number(match[1]),
										ppid: Number(match[2]),
										command: match[3],
									},
								]
							: []
					}),
				)
			},
		)
	})
}

/** Read-only: find a descendant of `root` whose command matches. */
async function findDescendant(
	root: number,
	command: RegExp,
	fixture: PiFixture,
): Promise<{pid: number; lstart: string}> {
	let found: {pid: number; lstart: string} | undefined
	await waitUntil(async () => {
		const rows = await processRows()
		const below = new Set([root])
		let grew = true
		while (grew) {
			grew = false
			for (const row of rows)
				if (below.has(row.ppid) && !below.has(row.pid)) {
					below.add(row.pid)
					grew = true
				}
		}
		const match = rows.find(
			(row) => below.has(row.pid) && command.test(row.command),
		)
		const lstart = match && (await readProcessTable())?.get(match.pid)
		if (match && lstart) found = {pid: match.pid, lstart}
		return found !== undefined
	}, 30_000)
	const result = found as {pid: number; lstart: string}
	fixture.recorded.push(result)
	return result
}

async function isAlive(process: {
	pid: number
	lstart: string
}): Promise<boolean> {
	return (
		classifyProcess(await readProcessTable(), process.pid, process.lstart) ===
		'alive'
	)
}

async function runningChild(
	dir: string,
	fixture: PiFixture,
): Promise<{pid: number; lstart: string}> {
	const state = await waitForState(
		dir,
		(current) =>
			current.attempt?.phase === 'running' && Boolean(current.attempt.lstart),
	)
	const child = {
		pid: state.attempt?.pid as number,
		lstart: state.attempt?.lstart as string,
	}
	fixture.recorded.push(child)
	return child
}

const SLEEP_TOOL = {
	toolCall: {name: 'bash', arguments: {command: 'sleep 1000'}},
}

test(
	'stopping a loop lets Pi clean up the running tool process',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([SLEEP_TOOL])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {message: '/loop 30s wait'})
					const dir = await loopDir(fixture.state)
					const child = await runningChild(dir, fixture)
					const tool = await findDescendant(child.pid, /^sleep 1000$/, fixture)
					await rpc.send('prompt', {message: '/loop stop'}, 30_000)
					const state = await waitForState(
						dir,
						(current) => current.status === 'stopped',
					)
					assert.equal(state.attempt?.finalized, true)
					await waitUntil(
						async () => !(await isAlive(child)) && !(await isAlive(tool)),
					)
					assert.equal(await rpc.close(), 0)
					assert.equal(rpc.stderr, '')
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'an owner crash stops the child and its tool, and the next owner recovers the run',
	{timeout: 180_000},
	async () => {
		const model = await ScriptedModel.start([SLEEP_TOOL])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const sessionId = randomUUID()
				const args = [...OWNER_ARGS, '--session-id', sessionId]
				const crashed = await PiRpc.start(args, {
					cwd: fixture.project,
					env: fixture.env,
				})
				let dir: string
				try {
					await crashed.send('prompt', {message: '/loop 30s wait'})
					dir = await loopDir(fixture.state)
					const config = JSON.parse(
						await readFile(join(dir, FILES.config), 'utf8'),
					) as LoopConfig
					assert.equal(config.ownerSessionId, sessionId)
					const child = await runningChild(dir, fixture)
					const tool = await findDescendant(child.pid, /^sleep 1000$/, fixture)
					process.kill(crashed.pid as number, 'SIGKILL')
					await crashed.waitForExit()
					await waitUntil(
						async () => !(await isAlive(child)) && !(await isAlive(tool)),
						20_000,
					)
					const state = await readStateFile(dir)
					assert.equal(state.iteration, 1)
					assert.equal(state.attempt?.finalized, false)
				} finally {
					crashed.kill()
				}

				const next = await PiRpc.start(args, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await next.waitFor(
						(record) =>
							record.method === 'notify' &&
							/has held the loop inbox/.test(record.message ?? ''),
					)
					await rm(join(fixture.state, 'inboxes', sessionId, 'receiver.lock'))
					const {records} = await next.send('prompt', {
						message: '/loop resolve',
					})
					assert.ok(
						records.some((record) =>
							/Resolved the earlier run/.test(record.message ?? ''),
						),
						JSON.stringify(records),
					)
					const state = await readStateFile(dir)
					assert.equal(state.attempt?.finalized, true)
					assert.equal(state.iteration, 1)
					assert.match(
						await readFile(join(dir, FILES.latest), 'utf8'),
						/owner Pi ended before this run finished/,
					)
					assert.equal(model.requests.length, 1)
					assert.equal(await next.close(), 0)
				} finally {
					next.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'a child whose owner died before it loaded exits without any model request',
	{timeout: 60_000},
	async () => {
		const model = await ScriptedModel.start([{text: 'must not happen'}])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const dir = join(fixture.state, 'orphan')
				await mkdir(dir)
				const pi = await executable('pi')
				// The launcher exits at once, so the child's parent is already gone
				// by the time its extensions load.
				const launcher = `const {spawn} = require('node:child_process')
const child = spawn(${JSON.stringify(pi)}, ['--no-session', '-p', '--no-extensions', '--extension', ${JSON.stringify(LOOP_EXTENSION)}, '--model', 'scripted/test', 'hello'], {
	detached: true,
	stdio: 'ignore',
	env: {...process.env, PI_LOOP_DIR: ${JSON.stringify(dir)}, PI_LOOP_ITERATION: '1', PI_LOOP_PARENT_PID: String(process.pid)},
})
process.stdout.write(child.pid + '\\n')
process.exit(0)`
				const output = await new Promise<string>((resolve, reject) =>
					execFile(
						process.execPath,
						['-e', launcher],
						{env: fixture.env, cwd: fixture.project},
						(error, stdout) => (error ? reject(error) : resolve(stdout)),
					),
				)
				const pid = Number(output.trim())
				assert.ok(pid > 1, output)
				await waitUntil(
					async () => !(await readProcessTable())?.has(pid),
					30_000,
				)
				assert.equal(model.requests.length, 0)
				assert.equal(
					existsSync(join(dir, FILES.results, '1.child.json')),
					false,
				)
			})
		} finally {
			model.close()
		}
	},
)

test(
	'a reload during a run keeps the child and finalizes it exactly once',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{toolCall: {name: 'bash', arguments: {command: 'sleep 3'}}},
			{text: 'done after reload'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(
					[...OWNER_ARGS, '--extension', join(fixture.root, 'probe.ts')],
					{cwd: fixture.project, env: fixture.env},
				)
				try {
					await rpc.send('prompt', {message: '/loop 30s wait'})
					const dir = await loopDir(fixture.state)
					const child = await runningChild(dir, fixture)
					await findDescendant(child.pid, /^sleep 3$/, fixture)
					await rpc.send('prompt', {message: '/probe-reload'}, 30_000)
					assert.equal(await isAlive(child), true, await loopDiagnostics(dir))
					const state = await waitForState(
						dir,
						(current) => current.attempt?.finalized === true,
					)
					assert.equal(state.lastExitCode, 0, await loopDiagnostics(dir))
					await waitForState(dir, (current) => current.status === 'scheduled')
					const runs = await readFile(join(dir, FILES.runs), 'utf8')
					assert.equal(runs.match(/— iteration 1\n/g)?.length, 1)
					assert.match(runs, /done after reload/)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'switching to a new session stops the loops of the old one',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([SLEEP_TOOL])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(
					[...OWNER_ARGS, '--extension', join(fixture.root, 'probe.ts')],
					{cwd: fixture.project, env: fixture.env},
				)
				try {
					await rpc.send('prompt', {message: '/loop 30s wait'})
					const dir = await loopDir(fixture.state)
					const child = await runningChild(dir, fixture)
					const tool = await findDescendant(child.pid, /^sleep 1000$/, fixture)
					await rpc.send('prompt', {message: '/probe-new'}, 60_000)
					const state = await waitForState(
						dir,
						(current) => current.status === 'stopped',
					)
					assert.equal(state.attempt?.finalized, true)
					await waitUntil(
						async () => !(await isAlive(child)) && !(await isAlive(tool)),
					)
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'a second Pi on the same session cannot control its loops',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{text: 'nightly'},
			{text: 'noted'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const sessionId = randomUUID()
				const args = [...OWNER_ARGS, '--session-id', sessionId]
				const owner = await PiRpc.start(args, {
					cwd: fixture.project,
					env: fixture.env,
				})
				// The owner must hold the session lock before the second Pi starts.
				await owner.send('prompt', {
					message: '/loop --passive daily 03:00 nightly',
				})
				const dir = await loopDir(fixture.state)
				await waitForState(
					dir,
					(state) =>
						state.attempt?.finalized === true && state.status === 'scheduled',
				)
				const second = await PiRpc.start(args, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await second.waitFor(
						(record) =>
							record.method === 'notify' &&
							/has held the loop inbox/.test(record.message ?? ''),
					)
					const {records} = await second.send('prompt', {message: '/loop stop'})
					assert.ok(
						records.some((record) =>
							/has held the loop inbox/.test(record.message ?? ''),
						),
					)
					assert.equal((await readStateFile(dir)).status, 'scheduled')
					// Listing is read-only and works without the lock; it opens a dialog.
					const from = second.records.length
					const listing = second.send('prompt', {message: '/loop list'})
					const dialog = await second.waitFor(
						(record) => record.method === 'editor',
						{from},
					)
					assert.match(
						String((dialog as unknown as {prefill?: string}).prefill),
						/nightly|daily at 03:00/,
					)
					second.respond({
						type: 'extension_ui_response',
						id: dialog.id,
						cancelled: true,
					})
					assert.equal((await listing).response.success, true)
					await owner.send('prompt', {message: '/loop stop'})
					assert.equal((await readStateFile(dir)).status, 'stopped')
					assert.equal(await second.close(), 0)
					assert.equal(await owner.close(), 0)
				} finally {
					second.kill()
					owner.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'restarting a loop of another session offers a copy here',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{text: 'nightly report'},
			{text: 'copy report'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const first = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				let original: LoopConfig
				try {
					await first.send('prompt', {
						message: '/loop --passive daily 03:00 nightly report',
					})
					const dir = await loopDir(fixture.state)
					await waitForState(dir, (state) => state.attempt?.finalized === true)
					original = JSON.parse(
						await readFile(join(dir, FILES.config), 'utf8'),
					) as LoopConfig
					assert.equal(await first.close(), 0)
					assert.equal((await readStateFile(dir)).status, 'stopped')
				} finally {
					first.kill()
				}
				const second = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					const from = second.records.length
					const pending = second.send('prompt', {
						message: `/loop restart ${original.id}`,
					})
					const dialog = await second.waitFor(
						(record) => record.method === 'confirm',
						{from},
					)
					second.respond({
						type: 'extension_ui_response',
						id: dialog.id,
						confirmed: true,
					})
					await pending
					const configs = await Promise.all(
						(await readdir(fixture.state))
							.filter((name) => name !== 'inboxes' && name !== original.id)
							.map(
								async (name) =>
									JSON.parse(
										await readFile(
											join(fixture.state, name, FILES.config),
											'utf8',
										),
									) as LoopConfig,
							),
					)
					assert.equal(configs.length, 1)
					assert.equal(configs[0].prompt, original.prompt)
					assert.equal(configs[0].delivery, original.delivery)
					assert.deepEqual(configs[0].schedule, original.schedule)
					assert.notEqual(configs[0].ownerSessionId, original.ownerSessionId)
					await second.send('prompt', {message: '/loop stop all'})
					assert.equal(await second.close(), 0)
				} finally {
					second.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'a detached background process can outlive its run (documented limit)',
	{timeout: 120_000},
	async () => {
		// A new session, as setsid or a daemon would create, so no process
		// group signal can reach it.
		const detach = `${process.execPath} -e 'const c = require("node:child_process").spawn("sleep", ["1000"], {detached: true, stdio: "ignore"}); c.unref(); console.log("bg:" + c.pid)'`
		const model = await ScriptedModel.start([
			{toolCall: {name: 'bash', arguments: {command: detach}}},
			{text: 'started a background job'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {message: '/loop 30s background'})
					const dir = await loopDir(fixture.state)
					await waitForState(
						dir,
						(current) => current.attempt?.finalized === true,
					)
					const pid = Number(
						JSON.stringify(model.requests[1]).match(/bg:(\d+)/)?.[1],
					)
					assert.ok(pid > 1)
					const lstart = (await readProcessTable())?.get(pid)
					if (lstart) fixture.recorded.push({pid, lstart})
					// Pi's cleanup covers tracked tool processes only; this one was
					// detached from its finished tool, as the README states.
					assert.ok(lstart, 'the background process survived its run')
					const readme = await readFile(
						new URL('./README.md', import.meta.url),
						'utf8',
					)
					assert.match(readme, /setsid/)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test('a stuck child gets KILL on its own group only; its detached tool survives (documented limit)', async () => {
	const script = `process.on('SIGTERM', () => {})
const tool = require('node:child_process').spawn('sleep', ['1000'], {detached: true, stdio: 'ignore'})
process.stdout.write(tool.pid + '\\n')
setInterval(() => {}, 1000)`
	const signals: Array<[number, NodeJS.Signals]> = []
	const h = await harness({
		spawnChild: (command, args, options) => spawn(command, args, options),
		invocation: [process.execPath, '-e', script, '--'],
		readProcessTable,
		kill: (pid, signal) => {
			signals.push([pid, signal])
			process.kill(pid, signal)
		},
		termGraceMs: 300,
		killWaitMs: 5000,
	})
	let tool: {pid: number; lstart: string} | undefined
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		const started = Date.now()
		await waitUntil(
			async () =>
				/^\d+/.test(
					await readFile(join(entry.dir, FILES.stdout), 'utf8').catch(() => ''),
				),
			30_000,
		).catch(async (error) => {
			throw new Error(
				`${error.message} after ${Date.now() - started} ms\n${await loopDiagnostics(entry.dir)}`,
			)
		})
		const toolPid = Number(
			(await readFile(join(entry.dir, FILES.stdout), 'utf8')).trim(),
		)
		const toolLstart = (await readProcessTable())?.get(toolPid)
		assert.ok(toolLstart)
		tool = {pid: toolPid, lstart: toolLstart}
		const child = (await readStateFile(entry.dir)).attempt?.pid as number
		assert.equal(await stopLoop(h.rt, entry), 'stopped')
		assert.deepEqual(signals, [
			[child, 'SIGTERM'],
			[-child, 'SIGKILL'],
		])
		assert.equal(await isAlive(tool), true)
	} finally {
		if (tool && (await isAlive(tool))) process.kill(tool.pid, 'SIGKILL')
		await h.close()
	}
})

// --- Inbox: messages, batches, budget, records, cards ---

const SESSION = 'session-1'

function report(
	loopId: string,
	iteration: number,
	fields: Partial<LoopInboxMessage> = {},
): LoopInboxMessage {
	return {
		version: 1,
		id: reportId(loopId, iteration),
		kind: 'report',
		ownerSessionId: SESSION,
		loopId,
		iteration,
		text: `report ${iteration} of ${loopId}`,
		status: 'completed',
		createdAt: new Date(Date.UTC(2026, 9, 14, 8, 0, iteration)).toISOString(),
		...fields,
	}
}

function note(
	loopId: string,
	iteration: number,
	index: number,
	createdAt?: string,
): LoopInboxMessage {
	return {
		...report(loopId, iteration),
		id: noteId(loopId, iteration, index),
		kind: 'note',
		text: `note ${index}`,
		createdAt:
			createdAt ??
			new Date(Date.UTC(2026, 9, 14, 8, 0, iteration)).toISOString(),
	}
}

const batchOptions = (overrides: Partial<BatchOptions> = {}): BatchOptions => ({
	maxFull: new Map(),
	held: new Set(),
	modeOf: () => 'passive',
	...overrides,
})

test('messages must match their file name, their kind, and their inbox owner', () => {
	const good = report('aa-11', 3)
	assert.deepEqual(validateMessage(good, `${good.id}.json`, SESSION), good)
	assert.equal(
		validateMessage(good, 'other.json', SESSION),
		'id does not match the file name',
	)
	assert.equal(
		validateMessage(good, `${good.id}.json`, 'session-2'),
		'belongs to another session',
	)
	assert.equal(
		validateMessage({...good, iteration: 4}, `${good.id}.json`, SESSION),
		'kind, loop, or iteration does not match the id',
	)
	assert.equal(
		validateMessage(
			{...good, text: 'x'.repeat(MAX_TEXT_BYTES + 1)},
			`${good.id}.json`,
			SESSION,
		),
		'text too large',
	)
	const n = note('aa-11', 3, 1)
	assert.deepEqual(validateMessage(n, `${n.id}.json`, SESSION), n)
	assert.equal(parseInboxId('note.aa-11.3'), undefined)
	assert.equal(parseInboxId('report.aa-11.3.1'), undefined)
	assert.equal(parseInboxId('report.a.b-11.3'), undefined)
})

test('several reports of one loop become the newest body plus a digest', () => {
	const batch = buildBatch(
		[report('aa-11', 1), report('aa-11', 2), report('aa-11', 3)],
		batchOptions(),
	)
	assert.ok(batch)
	assert.equal(batch.items.length, 1)
	const [item] = batch.items
	assert.equal(item.kind, 'report')
	assert.equal(item.iteration, 3)
	assert.deepEqual(item.messageIds, [reportId('aa-11', 3)])
	assert.deepEqual(item.supersededIds, [
		reportId('aa-11', 1),
		reportId('aa-11', 2),
	])
	assert.deepEqual(
		item.digest.map((line) => line.headline),
		['report 1 of aa-11', 'report 2 of aa-11'],
	)
	assert.deepEqual(batch.fullReports, [{loopId: 'aa-11', iteration: 3}])
})

test('iterations order numerically, not as strings', () => {
	const batch = buildBatch(
		[report('aa-11', 10), report('aa-11', 2)],
		batchOptions(),
	)
	assert.equal(batch?.items[0].iteration, 10)
	assert.deepEqual(batch?.items[0].supersededIds, [reportId('aa-11', 2)])
})

test('a 121-report backlog delivers every report exactly once, with one full body', () => {
	let pending = Array.from({length: 121}, (_, index) =>
		report('aa-11', index + 1),
	)
	const maxFull = new Map<string, number>()
	const covered: string[] = []
	const bodies: number[] = []
	for (let round = 0; round < 10 && pending.length > 0; round += 1) {
		const batch = buildBatch(pending, batchOptions({maxFull}))
		assert.ok(batch)
		for (const item of batch.items) {
			if (item.kind === 'report') bodies.push(item.iteration as number)
			if (item.kind === 'digest') {
				assert.equal(item.text, undefined)
				assert.equal(item.supersededBy, 121)
				assert.ok(item.supersededIds.length <= DIGEST_LIMIT)
			}
		}
		const ids = new Set([...batch.messageIds, ...batch.supersededIds])
		covered.push(...ids)
		for (const full of batch.fullReports)
			maxFull.set(
				full.loopId,
				Math.max(maxFull.get(full.loopId) ?? 0, full.iteration),
			)
		pending = pending.filter((message) => !ids.has(message.id))
	}
	assert.deepEqual(bodies, [121])
	assert.equal(pending.length, 0)
	assert.equal(covered.length, 121)
	assert.equal(new Set(covered).size, 121)
})

test('notes are never merged and follow their own report', () => {
	const batch = buildBatch(
		[
			report('aa-11', 1),
			note('aa-11', 1, 2),
			note('aa-11', 1, 1),
			report('aa-11', 2),
		],
		batchOptions(),
	)
	assert.ok(batch)
	assert.deepEqual(
		batch.items.map((item) => [item.kind, item.iteration, item.id]),
		[
			['note', 1, noteId('aa-11', 1, 1)],
			['note', 1, noteId('aa-11', 1, 2)],
			['report', 2, reportId('aa-11', 2)],
		],
	)
})

test('a held loop is skipped, and one batch has one mode chosen by the oldest head', () => {
	const old = report('re-01', 1, {createdAt: '2026-10-14T07:00:00.000Z'})
	const passive = Array.from({length: 4}, (_, index) =>
		report(`pa-0${index}`, 1, {createdAt: '2026-10-14T09:00:00.000Z'}),
	)
	const modeOf = (loopId: string) =>
		(loopId.startsWith('re') ? 'reactive' : 'passive') as Delivery
	const first = buildBatch([old, ...passive], batchOptions({modeOf}))
	assert.equal(first?.mode, 'reactive')
	assert.deepEqual(
		first?.items.map((item) => item.loopId),
		['re-01'],
	)
	const held = buildBatch(
		[old, ...passive],
		batchOptions({modeOf, held: new Set(['re-01'])}),
	)
	assert.equal(held?.mode, 'passive')
	assert.equal(held?.items.length, 4)
	assert.equal(
		buildBatch([old], batchOptions({modeOf, only: 'passive'})),
		undefined,
	)
})

test('the largest valid report fits the delivery budget with a notice', () => {
	const ascii = report('aa-11', 1, {
		text: 'a'.repeat(MAX_TEXT_BYTES),
		status: 'failed',
		error: 'e'.repeat(MAX_ERROR_BYTES),
	})
	const emoji = report('aa-11', 2, {text: '😀'.repeat(MAX_TEXT_BYTES / 4)})
	const escaped = report('aa-11', 3, {
		text: '"\\\u0001'.repeat(Math.floor(MAX_TEXT_BYTES / 3)),
	})
	for (const message of [ascii, emoji, escaped]) {
		const batch = buildBatch([message], batchOptions())
		assert.ok(batch, message.id)
		const [item] = batch.items
		assert.ok(payloadBytes(batch.items) <= BUDGET_BYTES, message.id)
		assert.equal(item.truncated, true)
		assert.match(
			item.text ?? '',
			/truncated for delivery: \d+ of \d+ characters/,
		)
		assert.deepEqual(item.messageIds, [message.id])
	}
})

test('the fixed part of one item stays under 96 KB in the worst case', () => {
	const loopId = 'aaaaaaaaaa-bbbbbb'
	const digest = Array.from({length: DIGEST_LIMIT}, (_, index) =>
		report(loopId, index + 1, {
			text: '😀"\\'.repeat(200),
			status: 'failed',
			exitCode: 255,
		}),
	)
	const newest = report(loopId, 99999, {
		text: '',
		status: 'failed',
		exitCode: 255,
		durationSeconds: 99999,
	})
	const batch = buildBatch([...digest, newest], batchOptions())
	assert.ok(batch)
	assert.equal(batch.items[0].supersededIds.length, DIGEST_LIMIT)
	assert.ok(
		payloadBytes(batch.items) <= 96 * 1024,
		String(payloadBytes(batch.items)),
	)
})

test('model content starts with the framing and explains failures', () => {
	const failed = report('aa-11', 4, {
		text: '',
		status: 'failed',
		exitCode: 3,
		error: 'boom',
	})
	const batch = buildBatch([failed, report('bb-22', 1)], batchOptions())
	const content = renderContent(batch?.items ?? [])
	assert.ok(content.startsWith(FRAMING))
	assert.match(
		content,
		/The run ended before it reported \(exit 3\)\. See \/loop show aa-11\./,
	)
	assert.match(content, /Error: boom/)
	assert.match(content, /report 1 of bb-22/)
	const digestOnly = buildBatch(
		[report('aa-11', 1)],
		batchOptions({maxFull: new Map([['aa-11', 5]])}),
	)
	assert.match(
		renderContent(digestOnly?.items ?? []),
		/superseded by iteration 5/,
	)
})

test('only complete session records acknowledge deliveries', () => {
	const record = (details: object, customType = INBOX_CUSTOM_TYPE) =>
		JSON.stringify({type: 'custom_message', customType, details})
	const content = [
		record({
			messageIds: ['report.aa-11.3'],
			supersededIds: ['report.aa-11.1'],
			items: [{kind: 'report', loopId: 'aa-11', iteration: 3}],
		}),
		record({messageIds: ['report.zz-99.1']}, 'other'),
		JSON.stringify({type: 'message', message: {role: 'user'}}),
		record({messageIds: ['report.bb-22.1']}).slice(0, 40),
	].join('\n')
	const recorded = parseSessionRecords(content)
	assert.deepEqual([...recorded.ids].sort(), [
		'report.aa-11.1',
		'report.aa-11.3',
	])
	assert.equal(recorded.maxFull.get('aa-11'), 3)
	assert.equal(
		parseSessionRecords(`${content}\n`).ids.has('report.bb-22.1'),
		false,
	)
})

const plainTools: CardTools = {
	fg: (_color, text) => text,
	bold: (text) => text,
	markdown: (text) => text.split('\n'),
	truncate: (text, width) => [...text].slice(0, width).join(''),
	width: (text) => [...text].length,
}

test('cards hide the framing, always show everything, and mark old entries', () => {
	const long = report('aa-11', 7, {
		text: Array.from({length: 10}, (_, index) => `line ${index}`).join('\n'),
		durationSeconds: 12,
	})
	const batch = buildBatch([report('aa-11', 6), long], batchOptions())
	const items = batch?.items ?? []
	const lines = cardLines(items, {}, 60, plainTools)
	const card = lines.join('\n')
	assert.equal(card.includes(FRAMING), false)
	assert.match(card, /↻ aa-11 · #7 · report/)
	assert.match(card, /✓ · 12s · \d\d:\d\d · in context · untrusted/)
	assert.match(card, /1 missed runs/)
	assert.match(card, /#6 \d\d:\d\d — report 6 of aa-11/)
	assert.match(card, /line 9/)
	assert.equal(/more lines|Ctrl\+O/.test(card), false)
	for (const line of lines) assert.ok([...line].length <= 60, line)
	const digestOnly = buildBatch(
		[report('aa-11', 1)],
		batchOptions({maxFull: new Map([['aa-11', 5]])}),
	)
	const digestCard = cardLines(
		digestOnly?.items ?? [],
		{},
		60,
		plainTools,
	).join('\n')
	assert.match(digestCard, /1 earlier runs/)
	assert.match(digestCard, /#1 \d\d:\d\d — report 1 of aa-11/)

	const old = legacyReportItem({
		loopId: 'aa-11',
		iteration: 2,
		report: formatReport(
			'aa-11',
			{
				iteration: 2,
				startedAt: 'A',
				finishedAt: '2026-10-14T08:00:00.000Z',
				durationSeconds: 5,
				exitCode: 1,
			},
			'old body',
			'',
		),
		finishedAt: '2026-10-14T08:00:00.000Z',
	})
	assert.equal(old.status, 'failed')
	assert.equal(old.exitCode, 1)
	assert.equal(old.durationSeconds, 5)
	assert.equal(old.text, 'old body\n')
	const legacy = cardLines([old], {displayOnly: true}, 60, plainTools).join(
		'\n',
	)
	assert.match(legacy, /display only/)
	assert.match(legacy, /old body/)
})

test('report headers parse from the shared report layout', () => {
	const text = formatReport(
		'aa-11',
		{
			iteration: 9,
			startedAt: 'A',
			finishedAt: 'B',
			durationSeconds: 4,
			error: 'spawn ENOENT',
		},
		'',
		'err',
	)
	const header = parseReportHeader(text)
	assert.equal(header.iteration, 9)
	assert.equal(header.exitCode, undefined)
	assert.equal(header.durationSeconds, 4)
	assert.equal(header.finishedAt, 'B')
	assert.match(header.body, /## stderr/)
})

// --- Receiver with a fake Pi ---

interface FakeSession {
	entries: Array<Record<string, unknown>>
	sent: Array<{
		message: {details: InboxDetails; content: string}
		options: Record<string, unknown>
	}>
	notices: string[]
	idle: boolean
	ctx: ExtensionContext
	pi: ExtensionAPI
}

function fakeSession(): FakeSession {
	const session: FakeSession = {
		entries: [],
		sent: [],
		notices: [],
		idle: true,
		ctx: undefined as never,
		pi: undefined as never,
	}
	session.ctx = {
		isIdle: () => session.idle,
		sessionManager: {getEntries: () => session.entries},
		ui: {notify: (message: string) => session.notices.push(message)},
	} as unknown as ExtensionContext
	session.pi = {
		sendMessage: (message: never, options: never) => {
			session.sent.push({message, options})
			if ((options as {triggerTurn?: boolean}).triggerTurn === false)
				session.entries.push({
					type: 'custom_message',
					customType: INBOX_CUSTOM_TYPE,
					details: (message as {details: unknown}).details,
				})
		},
	} as unknown as ExtensionAPI
	return session
}

async function receiverHarness(
	modes: Record<string, Delivery> = {},
	resetSubmissions = false,
) {
	const h = await harness()
	const session = fakeSession()
	const paths = inboxPaths(h.rt.root, h.rt.sessionId) as NonNullable<
		ReturnType<typeof inboxPaths>
	>
	h.rt.sessionFile = join(h.root, 'session.jsonl')
	const receiver = new Receiver(
		{
			pi: session.pi,
			rt: h.rt,
			isActive: () => true,
			modeOf: (loopId) => modes[loopId] ?? 'passive',
			resetSubmissions,
		},
		session.ctx,
	)
	await receiver.prepare()
	const write = (message: LoopInboxMessage) =>
		writeInboxMessage(paths.pending, {
			...message,
			ownerSessionId: h.rt.sessionId,
		})
	const record = async (details: InboxDetails) =>
		writeFile(
			h.rt.sessionFile as string,
			`${JSON.stringify({type: 'custom_message', customType: INBOX_CUSTOM_TYPE, details})}\n`,
			{flag: 'a'},
		)
	return {h, session, paths, receiver, write, record}
}

test('an idle passive report is sent once and deleted only after the session file records it', async () => {
	const {h, session, paths, receiver, write, record} = await receiverHarness()
	try {
		await write(report('aa-11', 1))
		await receiver.drain()
		assert.equal(session.sent.length, 1)
		assert.deepEqual(session.sent[0].options, {triggerTurn: false})
		assert.deepEqual(session.sent[0].message.details.messageIds, [
			reportId('aa-11', 1),
		])
		assert.ok(session.sent[0].message.content.startsWith(FRAMING))
		assert.equal(
			session.notices.filter((n) => n.includes('#1 report')).length,
			1,
		)
		await receiver.drain()
		assert.equal(session.sent.length, 1, 'live entries prevent a second send')
		assert.deepEqual(await readdir(paths.pending), [
			`${reportId('aa-11', 1)}.json`,
		])
		await record(session.sent[0].message.details)
		await receiver.drain()
		assert.deepEqual(await readdir(paths.pending), [])
		assert.equal(
			session.notices.filter((n) => n.includes('#1 report')).length,
			1,
		)
	} finally {
		await h.close()
	}
})

test('a busy session sends nothing; passive reports become turn_end drafts', async () => {
	const {h, session, receiver, write} = await receiverHarness({
		'rr-22': 'reactive',
	})
	try {
		session.idle = false
		await write(report('aa-11', 1))
		await write(report('rr-22', 1))
		await receiver.drain()
		assert.equal(session.sent.length, 0)
		const existing = {
			type: 'custom_message',
			customType: 'other',
			content: 'x',
			display: false,
		}
		const result = receiver.turnEnd(
			{entries: [existing]} as unknown as TurnEndEvent,
			session.ctx,
		)
		assert.ok(result?.entries)
		assert.equal(result.entries.length, 2)
		assert.deepEqual(result.entries[0], existing)
		assert.equal(result.continue, undefined)
		const draft = result.entries[1] as {
			customType: string
			details: InboxDetails
		}
		assert.equal(draft.customType, INBOX_CUSTOM_TYPE)
		assert.deepEqual(draft.details.messageIds, [reportId('aa-11', 1)])
	} finally {
		await h.close()
	}
})

test('a reactive send is recorded and never resent by the same runtime', async () => {
	const {h, session, receiver, write, record} = await receiverHarness({
		'rr-22': 'reactive',
	})
	try {
		await write(report('rr-22', 1))
		await receiver.drain()
		assert.equal(session.sent.length, 1)
		assert.deepEqual(session.sent[0].options, {
			triggerTurn: true,
			deliverAs: 'followUp',
		})
		assert.equal(h.rt.submissions.length, 1)
		await write(report('rr-22', 2))
		await receiver.drain()
		assert.equal(
			session.sent.length,
			1,
			'the loop is held while its report may be queued',
		)
		await record(session.sent[0].message.details)
		await receiver.drain()
		assert.deepEqual(
			h.rt.submissions.map((submission) => submission.coveredIds),
			[[reportId('rr-22', 2)]],
		)
		assert.equal(session.sent.length, 2)
		assert.deepEqual(session.sent[1].message.details.messageIds, [
			reportId('rr-22', 2),
		])
	} finally {
		await h.close()
	}
})

test('a new AgentSession forgets old submissions after the disk check', async () => {
	const {h, session, receiver, write} = await receiverHarness(
		{'rr-22': 'reactive'},
		true,
	)
	try {
		h.rt.submissions.push({
			seq: 1,
			submittedMono: 0,
			coveredIds: [reportId('rr-22', 1)],
			fullReports: [],
		})
		await write(report('rr-22', 1))
		await receiver.drain()
		assert.equal(session.sent.length, 1)
		assert.deepEqual(session.sent[0].message.details.messageIds, [
			reportId('rr-22', 1),
		])
	} finally {
		await h.close()
	}
})

test('invalid inbox files are quarantined with one notice', async () => {
	const {h, session, paths, receiver} = await receiverHarness()
	try {
		await writeFile(join(paths.pending, 'report.aa-11.1.json'), '{not json')
		await writeFile(
			join(paths.pending, 'report.aa-11.2.json'),
			JSON.stringify({...report('aa-11', 2), ownerSessionId: 'someone-else'}),
		)
		await receiver.drain()
		assert.deepEqual(await readdir(paths.pending), [])
		assert.deepEqual((await readdir(paths.rejected)).sort(), [
			'report.aa-11.1.json',
			'report.aa-11.2.json',
		])
		assert.equal(
			session.notices.filter((n) => n.includes('rejected/')).length,
			2,
		)
		assert.equal(session.sent.length, 0)
	} finally {
		await h.close()
	}
})

test('superseded reports recorded before a crash are deleted, never sent', async () => {
	const {h, session, paths, receiver, write, record} = await receiverHarness()
	try {
		await write(report('aa-11', 1))
		await write(report('aa-11', 2))
		await record({
			messageIds: [reportId('aa-11', 3)],
			supersededIds: [reportId('aa-11', 1), reportId('aa-11', 2)],
			items: [],
		})
		await receiver.drain()
		assert.deepEqual(await readdir(paths.pending), [])
		assert.equal(session.sent.length, 0)
	} finally {
		await h.close()
	}
})

test('a stopped receiver never sends', async () => {
	const {h, session, receiver, write} = await receiverHarness()
	try {
		await write(report('aa-11', 1))
		await receiver.stop()
		await receiver.drain()
		assert.equal(
			receiver.turnEnd({entries: []} as unknown as TurnEndEvent, session.ctx),
			undefined,
		)
		assert.equal(session.sent.length, 0)
	} finally {
		await h.close()
	}
})

test(
	'a result written before an owner crash is published once at the next start',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([{text: 'noted'}])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const sessionId = randomUUID()
				const id = 'mrecov1-abcdef'
				const dir = join(fixture.state, id)
				await mkdir(join(dir, FILES.results), {recursive: true})
				await writeConfig(dir, {
					version: 3,
					runtime: 'in-process',
					id,
					prompt: 'recover',
					schedule: {kind: 'interval', intervalMs: MINUTE},
					cwd: fixture.project,
					createdAt: new Date().toISOString(),
					ownerSessionId: sessionId,
				})
				await writePrivateFile(join(dir, FILES.prompt), 'recover\n')
				// The child finished and wrote its result; the owner died before
				// publishing it. PID 2 never matches a recorded start time.
				await writeStateFile(dir, {
					status: 'running',
					iteration: 1,
					attempt: {
						iteration: 1,
						phase: 'running',
						pid: 2,
						lstart: 'Thu Jan  1 00:00:00 1970',
						startedAt: new Date().toISOString(),
						finalized: false,
					},
				})
				const result: LoopInboxMessage = {
					...report(id, 1),
					ownerSessionId: sessionId,
					text: 'finished before the crash',
				}
				await writeFile(
					join(dir, FILES.results, '1.json'),
					JSON.stringify(result),
				)
				const rpc = await PiRpc.start(
					[...OWNER_ARGS, '--session-id', sessionId],
					{cwd: fixture.project, env: fixture.env},
				)
				try {
					await waitUntil(() => model.requests.length === 1, 30_000)
					const owner = JSON.stringify(model.requests[0])
					assert.match(owner, /finished before the crash/)
					await rpc.waitFor((record) => record.type === 'agent_settled')
					const state = await readStateFile(dir)
					assert.equal(state.attempt?.finalized, true)
					assert.equal(existsSync(join(dir, FILES.results, '1.json')), false)
					await waitUntil(
						async () =>
							(
								await readdir(
									join(fixture.state, 'inboxes', sessionId, 'pending'),
								)
							).length === 0,
						20_000,
					)
					assert.equal(model.requests.length, 1)
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

// --- Delivery modes ---

test('--passive opts a loop out of reactive delivery', () => {
	assert.deepEqual(parseStartArgs('45s check CI'), {
		schedule: {kind: 'interval', intervalMs: 45 * SECOND},
		prompt: 'check CI',
		delivery: 'reactive',
	})
	assert.deepEqual(parseStartArgs('--passive daily 09:00 summarize'), {
		schedule: {kind: 'daily', hour: 9, minute: 0},
		prompt: 'summarize',
		delivery: 'passive',
	})
	assert.deepEqual(parseStartArgs('--passive check'), {
		schedule: {kind: 'interval', intervalMs: 30 * MINUTE},
		prompt: 'check',
		delivery: 'passive',
	})
	assert.match(
		(parseStartArgs('--reactive 30m x') as {error: string}).error,
		/Unknown option --reactive/,
	)
	assert.match(
		(parseStartArgs('--safe 30m x') as {error: string}).error,
		/removed/,
	)
	assert.match(
		(parseStartArgs('--passive') as {error: string}).error,
		/prompt is required/,
	)
})

/** Two scripted providers, so child and owner requests never interleave. */
function twoModels(child: ScriptedModel, owner: ScriptedModel): string {
	const ownerProvider = JSON.parse(owner.modelsJson).providers.scripted
	const merged = JSON.parse(child.modelsJson)
	merged.providers.owner = ownerProvider
	return JSON.stringify(merged)
}

test(
	'a passive report reaches the context while idle without starting a turn',
	{timeout: 120_000},
	async () => {
		const child = await ScriptedModel.start([{text: 'passive report'}])
		const owner = await ScriptedModel.start([{text: 'I see it'}])
		try {
			await withPiFixture(twoModels(child, owner), async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {message: '/loop --passive 30s report'})
					const dir = await loopDir(fixture.state)
					const config = JSON.parse(
						await readFile(join(dir, FILES.config), 'utf8'),
					) as LoopConfig
					assert.equal(config.delivery, 'passive')
					await rpc.waitFor(
						(record) =>
							record.type === 'message_end' &&
							JSON.stringify(record).includes('passive report'),
					)
					await new Promise((resolve) => setTimeout(resolve, 500))
					assert.equal(
						owner.requests.length,
						0,
						'passive delivery starts no turn',
					)
					await rpc.send('set_model', {provider: 'owner', modelId: 'test'})
					await rpc.send('prompt', {message: 'what did the loop say?'})
					await rpc.waitFor((record) => record.type === 'agent_settled')
					assert.equal(owner.requests.length, 1)
					const request = JSON.stringify(owner.requests[0])
					assert.ok(request.includes(FRAMING))
					assert.match(request, /passive report/)

					const from = rpc.records.length
					const status = rpc.send('prompt', {message: '/loop status'})
					const dialog = await rpc.waitFor(
						(record) => record.method === 'editor',
						{from},
					)
					assert.match(
						String((dialog as unknown as {prefill?: string}).prefill),
						/delivery: passive/,
					)
					rpc.respond({
						type: 'extension_ui_response',
						id: dialog.id,
						cancelled: true,
					})
					await status
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			child.close()
			owner.close()
		}
	},
)

test(
	'a passive report that arrives during a busy run joins at the end of the turn',
	{timeout: 120_000},
	async () => {
		const child = await ScriptedModel.start([
			{toolCall: {name: 'bash', arguments: {command: 'sleep 2'}}},
			{text: 'passive report'},
		])
		const owner = await ScriptedModel.start([
			{toolCall: {name: 'bash', arguments: {command: 'sleep 8'}}},
			{text: 'done'},
		])
		try {
			await withPiFixture(twoModels(child, owner), async (fixture) => {
				const args = OWNER_ARGS.filter((arg) => arg !== '--no-tools').concat(
					'--tools',
					'bash',
				)
				const rpc = await PiRpc.start(args, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {message: '/loop --passive 30s report'})
					const dir = await loopDir(fixture.state)
					await rpc.send('set_model', {provider: 'owner', modelId: 'test'})
					await rpc.send('prompt', {message: 'work for a while'})
					await waitForState(
						dir,
						(state) => state.attempt?.finalized === true,
						30_000,
					)
					await rpc.waitFor((record) => record.type === 'agent_settled', {
						timeout: 60_000,
					})
					assert.equal(
						owner.requests.length,
						2,
						'no extra turn for a passive report',
					)
					assert.equal(
						JSON.stringify(owner.requests[0]).includes('passive report'),
						false,
					)
					const second = JSON.stringify(owner.requests[1])
					assert.ok(second.includes(FRAMING), second)
					assert.match(second, /passive report/)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			child.close()
			owner.close()
		}
	},
)

// --- loop_send notes ---

test('loop_send writes at most three bounded, valid notes per run', async () => {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-notes-')))
	try {
		const pending = join(root, 'pending')
		await mkdir(pending)
		const env = {
			PI_LOOP_ID: 'aa-11',
			PI_LOOP_OWNER_SESSION_ID: SESSION,
			PI_LOOP_ITERATION: '4',
			PI_LOOP_INBOX: pending,
		}
		const send = createNoteSender(env)
		assert.equal(await send('first'), 'Sent note 1 of 3 to the owner session.')
		await send('x'.repeat(MAX_NOTE_BYTES * 2))
		await send('third')
		await assert.rejects(send('fourth'), /already sent 3 notes/)
		const files = (await readdir(pending)).sort()
		assert.deepEqual(
			files,
			[1, 2, 3].map((n) => `${noteId('aa-11', 4, n)}.json`),
		)
		for (const file of files) {
			const message = validateMessage(
				JSON.parse(await readFile(join(pending, file), 'utf8')),
				file,
				SESSION,
			)
			assert.equal(typeof message, 'object', String(message))
		}
		const long = JSON.parse(
			await readFile(join(pending, files[1]), 'utf8'),
		) as LoopInboxMessage
		assert.ok(Buffer.byteLength(long.text) <= MAX_NOTE_BYTES)
		assert.match(long.text, /\[truncated\]$/)
		await assert.rejects(createNoteSender({})('x'), /only inside a loop run/)
	} finally {
		await rm(root, {recursive: true, force: true})
	}
})

test(
	'a real child sends a note before its final report',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{
				toolCall: {
					name: 'loop_send',
					arguments: {message: 'urgent: the build broke'},
				},
			},
			{text: 'final report'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {
						message: '/loop --passive 30s watch the build',
					})
					const dir = await loopDir(fixture.state)
					await waitForState(dir, (state) => state.attempt?.finalized === true)
					const delivered = (text: string) =>
						rpc.waitFor(
							(record) =>
								record.type === 'message_end' &&
								JSON.stringify(record).includes(text),
						)
					await delivered('urgent: the build broke')
					await delivered('final report')
					const tools = JSON.stringify(model.requests[0])
					assert.match(tools, /loop_send/)
					assert.match(tools, /only for results that cannot wait/)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

// --- Next-run messages and requeue ---

async function queueOwnerMessage(
	entry: LoopEntry,
	text: string,
	epoch: number,
): Promise<string> {
	const message: LoopOwnerMessage = {
		version: 1,
		id: ownerMessageId(epoch, 'abcd'),
		kind: 'message',
		text,
		createdAt: new Date(epoch).toISOString(),
	}
	await mkdir(join(entry.dir, FILES.inbox), {recursive: true})
	await writeFile(
		join(entry.dir, FILES.inbox, `${message.id}.json`),
		JSON.stringify(message),
	)
	return `${message.id}.json`
}

test('a run claims queued owner messages and attaches them in order', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		const first = await queueOwnerMessage(entry, 'first ask', 1000)
		const second = await queueOwnerMessage(entry, 'second ask', 2000)
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		const claim = join(entry.dir, FILES.claimed, '1')
		const attached = h.spawns[0].args.filter((arg) =>
			arg.startsWith(`@${claim}`),
		)
		assert.deepEqual(attached, [
			`@${join(claim, first)}`,
			`@${join(claim, second)}`,
		])
		assert.match(
			h.spawns[0].args.at(-1) as string,
			/instructions from the owner session/,
		)
		assert.deepEqual(await readdir(join(entry.dir, FILES.inbox)), [])
	} finally {
		await h.close()
	}
})

test('a failed run keeps its claim, and its report says how many need review', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await queueOwnerMessage(entry, 'do it', 1000)
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		exitWith(h.children[0], 1)
		await waitUntil(() => entry.state === 'scheduled')
		assert.deepEqual(
			(await needsReview(entry)).map((claim) => [
				claim.iteration,
				claim.files.length,
			]),
			[[1, 1]],
		)
		const paths = inboxPaths(h.rt.root, h.rt.sessionId) as NonNullable<
			ReturnType<typeof inboxPaths>
		>
		const published = JSON.parse(
			await readFile(
				join(paths.pending, `${reportId(entry.config.id, 1)}.json`),
				'utf8',
			),
		) as LoopInboxMessage
		assert.equal(published.status, 'failed')
		assert.equal(published.exitCode, 1)
		assert.equal(published.needsReview, 1)
		const content = renderContent(
			buildBatch([published], batchOptions())?.items ?? [],
		)
		assert.match(
			content,
			/1 owner message\(s\) for this run were not confirmed/,
		)
		const card = cardLines(
			buildBatch([published], batchOptions())?.items ?? [],
			{},
			70,
			plainTools,
		).join('\n')
		assert.match(card, /1 need review · \/loop requeue/)
	} finally {
		await h.close()
	}
})

test('requeue moves each unconfirmed message back once and keeps conflicts', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		const claim = join(entry.dir, FILES.claimed, '3')
		await mkdir(claim, {recursive: true})
		const write = async (directory: string, epoch: number, text: string) => {
			const message: LoopOwnerMessage = {
				version: 1,
				id: ownerMessageId(epoch, 'ab'),
				kind: 'message',
				text,
				createdAt: new Date(epoch).toISOString(),
			}
			await mkdir(directory, {recursive: true})
			await writeFile(
				join(directory, `${message.id}.json`),
				JSON.stringify(message),
			)
			return `${message.id}.json`
		}
		const plain = await write(claim, 1, 'plain')
		const same = await write(claim, 2, 'same')
		await write(join(entry.dir, FILES.inbox), 2, 'same')
		const differs = await write(claim, 3, 'mine')
		await write(join(entry.dir, FILES.inbox), 3, 'theirs')
		await writeFile(join(claim, 'message.4.ab.json'), '{broken')
		const outcome = await requeueMessages(entry)
		assert.equal(outcome.moved, 1)
		assert.deepEqual(
			outcome.kept.sort(),
			[join(claim, differs), join(claim, 'message.4.ab.json')].sort(),
		)
		assert.deepEqual(
			(await readdir(join(entry.dir, FILES.inbox))).sort(),
			[plain, same, differs].sort(),
		)
		assert.equal(existsSync(join(claim, same)), false)
		assert.equal(existsSync(join(claim, plain)), false)
		const again = await requeueMessages(entry)
		assert.equal(again.moved, 0)
	} finally {
		await h.close()
	}
})

test('requeue never touches the claim of a running iteration', async () => {
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await queueOwnerMessage(entry, 'in flight', 1000)
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		assert.deepEqual(await needsReview(entry), [])
		const outcome = await requeueMessages(entry)
		assert.equal(outcome.moved, 0)
		assert.equal((await readdir(join(entry.dir, FILES.claimed, '1'))).length, 1)
	} finally {
		await h.close()
	}
})

function capturingPi(): {
	pi: ExtensionAPI
	handlers: Map<string, (event: unknown, ctx: unknown) => Promise<void>>
} {
	const handlers = new Map<
		string,
		(event: unknown, ctx: unknown) => Promise<void>
	>()
	return {
		pi: {
			on: (
				name: string,
				handler: (event: unknown, ctx: unknown) => Promise<void>,
			) => handlers.set(name, handler),
		} as unknown as ExtensionAPI,
		handlers,
	}
}

test('a completed child removes its claim after writing its result; a failed one keeps it', async () => {
	for (const stopReason of ['stop', 'error']) {
		const dir = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-child-')))
		const scope = globalThis as unknown as Record<symbol, unknown>
		delete scope[CHILD_GUARD]
		const claim = join(dir, FILES.claimed, '2')
		await mkdir(claim, {recursive: true})
		await writeFile(join(claim, 'message.1.ab.json'), '{}')
		const {pi, handlers} = capturingPi()
		const stop = registerLoopChild(
			pi,
			{
				PI_LOOP_DIR: dir,
				PI_LOOP_ID: 'aa-11',
				PI_LOOP_OWNER_SESSION_ID: SESSION,
				PI_LOOP_PARENT_PID: String(process.ppid),
				PI_LOOP_ITERATION: '2',
				PI_LOOP_RESULT: join(dir, FILES.results, '2.json'),
			},
			throwingExit,
		) as () => void
		try {
			const ctx = {
				sessionManager: {
					getBranch: () => [
						{
							type: 'message',
							message: {
								role: 'assistant',
								stopReason,
								content: [{type: 'text', text: 'the report'}],
							},
						},
					],
				},
			}
			await handlers.get('agent_settled')?.({aborted: false}, ctx)
			const result = JSON.parse(
				await readFile(join(dir, FILES.results, '2.json'), 'utf8'),
			) as LoopInboxMessage
			assert.equal(
				typeof validateMessage(result, `${result.id}.json`, SESSION),
				'object',
			)
			assert.equal(result.text, 'the report')
			assert.equal(
				result.status,
				stopReason === 'stop' ? 'completed' : 'failed',
			)
			assert.equal(existsSync(claim), stopReason !== 'stop')
		} finally {
			stop()
			delete scope[CHILD_GUARD]
			await rm(dir, {recursive: true, force: true})
		}
	}
})

test(
	'a message queued with /loop send reaches the next run, which confirms it',
	{timeout: 150_000},
	async () => {
		const model = await ScriptedModel.start([
			{text: 'first run'},
			{text: 'second run'},
		])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {
						message: '/loop --passive 30s check the queue',
					})
					const dir = await loopDir(fixture.state)
					await waitForState(
						dir,
						(state) =>
							state.attempt?.finalized === true && state.iteration === 1,
					)
					const {records} = await rpc.send('prompt', {
						message: '/loop send also check PR 900',
					})
					assert.ok(
						records.some((record) =>
							/Queued a message/.test(record.message ?? ''),
						),
						JSON.stringify(records),
					)
					await waitForState(
						dir,
						(state) =>
							state.attempt?.finalized === true && state.iteration === 2,
						90_000,
					)
					const second = JSON.stringify(model.requests[1])
					assert.match(second, /also check PR 900/)
					assert.match(second, /instructions from the owner session/)
					assert.equal(existsSync(join(dir, FILES.claimed, '2')), false)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

// --- Terminal identity ---

test('a run does not inherit the owner pane identity', async () => {
	const saved = Object.fromEntries(
		PANE_IDENTITY_VARIABLES.map((name) => [name, process.env[name]]),
	)
	for (const name of PANE_IDENTITY_VARIABLES)
		process.env[name] = `owner-${name}`
	const h = await harness()
	try {
		const entry = await h.makeLoop()
		await scheduleLoop(h.rt, entry)
		await waitUntil(() => h.spawns.length === 1)
		const {env} = h.spawns[0]
		for (const name of PANE_IDENTITY_VARIABLES)
			assert.equal(name in env, false, name)
		assert.equal(env.PATH, process.env.PATH)
	} finally {
		for (const [name, value] of Object.entries(saved))
			if (value === undefined) delete process.env[name]
			else process.env[name] = value
		await h.close()
	}
})

test(
	'a real child sees no pane identity of the owner',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([{text: 'done'}])
		try {
			await withPiFixture(model.modelsJson, async (fixture) => {
				// Discovered by the child only; the owner runs with --no-extensions.
				await mkdir(join(fixture.root, 'agent', 'extensions'), {
					recursive: true,
				})
				await writeFile(
					join(fixture.root, 'agent', 'extensions', 'probe-env.ts'),
					`import {writeFileSync} from 'node:fs'
export default function () {
	if (!process.env.PI_LOOP_DIR) return
	writeFileSync(process.env.PI_LOOP_DIR + '/probe-env.json', JSON.stringify(${JSON.stringify(PANE_IDENTITY_VARIABLES)}.map((name) => process.env[name] ?? null)))
}
`,
				)
				const env = {
					...fixture.env,
					...Object.fromEntries(
						PANE_IDENTITY_VARIABLES.map((name) => [name, `owner-${name}`]),
					),
				}
				const rpc = await PiRpc.start(OWNER_ARGS, {cwd: fixture.project, env})
				try {
					await rpc.send('prompt', {message: '/loop --passive 30s say done'})
					const dir = await loopDir(fixture.state)
					await waitForState(dir, (state) => state.attempt?.finalized === true)
					const seen = JSON.parse(
						await readFile(join(dir, 'probe-env.json'), 'utf8'),
					)
					assert.deepEqual(
						seen,
						PANE_IDENTITY_VARIABLES.map(() => null),
					)
					await rpc.send('prompt', {message: '/loop stop'})
					assert.equal(await rpc.close(), 0)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)
