import {randomUUID} from 'node:crypto'
import {chmod, readFile, readdir, rename, rm, writeFile} from 'node:fs/promises'
import {homedir} from 'node:os'
import {join, resolve, sep} from 'node:path'

export const INTERVAL_MULTIPLIERS: Record<string, number> = {
	s: 1000,
	m: 60_000,
	h: 3_600_000,
	d: 86_400_000,
}
export const MIN_INTERVAL_MS = 30 * INTERVAL_MULTIPLIERS.s
export const MAX_INTERVAL_MS = 30 * INTERVAL_MULTIPLIERS.d
export const DEFAULT_INTERVAL_MS = 30 * INTERVAL_MULTIPLIERS.m
export const STATE_VERSION = 3
const MAX_LOG_BYTES = 10 * 1024 * 1024
const KEEP_LOG_BYTES = 5 * 1024 * 1024

// Single source for loop-dir file names, shared by the owner runtime, the
// child hooks, and the commands that display them.
export const FILES = {
	config: 'config.json',
	prompt: 'prompt.md',
	latest: 'latest.md',
	runs: 'runs.log',
	state: 'state.json',
	runtimeLog: 'runtime.log',
	commands: 'commands.jsonl',
	events: 'events.jsonl',
	stdout: 'run.stdout',
	stderr: 'run.stderr',
	results: 'results',
	inbox: 'inbox',
	claimed: 'claimed',
} as const

export interface IntervalSchedule {
	kind: 'interval'
	intervalMs: number
}

export interface DailySchedule {
	kind: 'daily'
	hour: number
	minute: number
}

export type LoopSchedule = IntervalSchedule | DailySchedule

export interface LoopConfig {
	version: number
	runtime: 'in-process'
	id: string
	prompt: string
	schedule: LoopSchedule
	// Kept for configs created before schedules were introduced.
	intervalMs?: number
	cwd: string
	createdAt: string
	ownerSessionId?: string
	provider?: string
	model?: string
	thinking?: string
	// Absent means reactive.
	delivery?: 'passive' | 'reactive'
}

export type LoopStatus = 'scheduled' | 'running' | 'stopping' | 'stopped'

export interface AttemptRecord {
	iteration: number
	phase: 'launching' | 'running' | 'done'
	pid: number | null
	lstart: string | null
	startedAt: string
	finalized: boolean
}

export interface LoopStateFile {
	status: LoopStatus
	iteration: number
	nextRunEpoch?: number
	lastStartedAt?: string
	lastFinishedAt?: string
	lastExitCode?: number
	lastDurationSeconds?: number
	ownerPid?: number
	attempt?: AttemptRecord
}

export function stateRoot(): string {
	if (process.env.PI_LOOP_STATE_DIR) return process.env.PI_LOOP_STATE_DIR
	return join(
		process.env.XDG_STATE_HOME ?? join(homedir(), '.local', 'state'),
		'pi-loop',
	)
}

export function isValidSchedule(schedule: LoopSchedule): boolean {
	if (schedule.kind === 'interval')
		return (
			Number.isFinite(schedule.intervalMs) &&
			schedule.intervalMs >= MIN_INTERVAL_MS &&
			schedule.intervalMs <= MAX_INTERVAL_MS
		)
	if (schedule.kind === 'daily')
		return (
			Number.isInteger(schedule.hour) &&
			Number.isInteger(schedule.minute) &&
			schedule.hour >= 0 &&
			schedule.hour <= 23 &&
			schedule.minute >= 0 &&
			schedule.minute <= 59
		)
	return false
}

export function formatDailyTime(schedule: DailySchedule): string {
	return `${String(schedule.hour).padStart(2, '0')}:${String(schedule.minute).padStart(2, '0')}`
}

export function makeId(): string {
	return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`
}

export async function readOptional(path: string): Promise<string | undefined> {
	return readFile(path, 'utf8').catch(() => undefined)
}

export async function writePrivateFile(
	path: string,
	content: string,
): Promise<void> {
	await writeFile(path, content, {encoding: 'utf8', mode: 0o600})
	await chmod(path, 0o600)
}

/** Readers never see a partial file: write a sibling, then rename it. */
export async function writeAtomic(
	path: string,
	content: string,
): Promise<void> {
	const temporary = `${path}.${process.pid}.${randomUUID()}.tmp`
	try {
		await writePrivateFile(temporary, content)
		await rename(temporary, path)
	} catch (error) {
		await rm(temporary, {force: true})
		throw error
	}
}

export async function truncateLog(path: string): Promise<void> {
	const content = await readFile(path).catch(() => undefined)
	if (!content || content.length <= MAX_LOG_BYTES) return
	await writeAtomic(path, content.subarray(-KEEP_LOG_BYTES).toString('utf8'))
}

/**
 * Session IDs become directory names, so reject anything that could leave
 * the inbox root, including the `.` and `..` components the pattern allows.
 */
export function isValidSessionId(sessionId: string): boolean {
	return (
		/^[A-Za-z0-9._-]{1,128}$/.test(sessionId) &&
		sessionId !== '.' &&
		sessionId !== '..'
	)
}

export function isValidLoopId(loopId: string): boolean {
	return /^[a-z0-9]+-[a-z0-9]+$/.test(loopId)
}

export function sessionDirectory(
	root: string,
	sessionId: string,
): string | undefined {
	if (!isValidSessionId(sessionId)) return undefined
	const inboxRoot = resolve(root, 'inboxes')
	const directory = resolve(inboxRoot, sessionId)
	return directory.startsWith(`${inboxRoot}${sep}`) ? directory : undefined
}

export async function readConfig(
	loopDir: string,
): Promise<LoopConfig | undefined> {
	const content = await readOptional(join(loopDir, FILES.config))
	if (!content) return undefined
	try {
		const config = JSON.parse(content) as LoopConfig
		if (!config.id) return undefined
		if (config.version !== STATE_VERSION || config.runtime !== 'in-process')
			return undefined
		// Normalize legacy interval-only configs at the read boundary so every
		// consumer can rely on config.schedule being present and valid.
		config.schedule ??= {
			kind: 'interval',
			intervalMs: config.intervalMs ?? DEFAULT_INTERVAL_MS,
		}
		if (!isValidSchedule(config.schedule)) return undefined
		return config
	} catch {
		return undefined
	}
}

export async function writeConfig(
	loopDir: string,
	config: LoopConfig,
): Promise<void> {
	await writeAtomic(
		join(loopDir, FILES.config),
		`${JSON.stringify(config, null, 2)}\n`,
	)
}

export async function listLoopConfigs(): Promise<
	Array<{dir: string; config: LoopConfig}>
> {
	const root = stateRoot()
	const entries = await readdir(root, {withFileTypes: true}).catch(() => [])
	const records = await Promise.all(
		entries
			.filter((entry) => entry.isDirectory() && entry.name !== 'inboxes')
			.map(async (entry) => {
				const dir = join(root, entry.name)
				const config = await readConfig(dir)
				return config ? {dir, config} : undefined
			}),
	)
	return records
		.filter((record) => record !== undefined)
		.sort((a, b) => b.config.createdAt.localeCompare(a.config.createdAt))
}

export async function readStateFile(loopDir: string): Promise<LoopStateFile> {
	const content = await readOptional(join(loopDir, FILES.state))
	if (content) {
		try {
			return JSON.parse(content) as LoopStateFile
		} catch {}
	}
	return {status: 'stopped', iteration: 0}
}

export async function writeStateFile(
	loopDir: string,
	state: LoopStateFile,
): Promise<void> {
	await writeAtomic(
		join(loopDir, FILES.state),
		`${JSON.stringify(state, null, 2)}\n`,
	)
}
