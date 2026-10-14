import {mkdirSync, renameSync, writeFileSync} from 'node:fs'
import {appendFile, rm} from 'node:fs/promises'
import {join} from 'node:path'
import type {
	ExtensionAPI,
	ExtensionContext,
} from '@earendil-works/pi-coding-agent'
import {FILES, isValidLoopId, isValidSessionId, writeAtomic} from './core.ts'
import {
	MAX_ERROR_BYTES,
	MAX_NOTE_BYTES,
	MAX_TEXT_BYTES,
	NOTES_PER_RUN,
	noteId,
	reportId,
	truncateBytes,
	writeInboxMessage,
	type LoopInboxMessage,
} from './inbox.ts'
import {readProcessTableSync} from './runtime.ts'

export const PARENT_WATCH_MS = 2000
// Exit status for a child whose owner was already gone when it loaded.
export const ORPHANED_EXIT_CODE = 75
const CHILD_GUARD = Symbol.for('pi-loop.child')

export function parseParentPid(value: string | undefined): number | undefined {
	if (!value || !/^\d+$/.test(value)) return undefined
	const pid = Number(value)
	return Number.isSafeInteger(pid) && pid > 1 ? pid : undefined
}

// The iteration is constant for a loop child's whole lifetime.
let auditIteration: number | undefined

async function appendLoopAudit(
	loopDir: string,
	filenames: string[],
	event: Record<string, unknown>,
): Promise<void> {
	try {
		const line = `${JSON.stringify({timestamp: new Date().toISOString(), iteration: auditIteration, ...event})}\n`
		await Promise.all(
			filenames.map((filename) =>
				appendFile(join(loopDir, filename), line, {
					encoding: 'utf8',
					mode: 0o600,
				}),
			),
		)
	} catch {
		// Observability must never break the recurring task.
	}
}

/** Lets reconciliation find this child even if the owner died first. */
function writeSelfRecord(loopDir: string, iteration: number): void {
	try {
		const lstart = readProcessTableSync()?.get(process.pid) ?? null
		const directory = join(loopDir, FILES.results)
		mkdirSync(directory, {recursive: true, mode: 0o700})
		const path = join(directory, `${iteration}.child.json`)
		const temporary = `${path}.${process.pid}.tmp`
		writeFileSync(temporary, JSON.stringify({pid: process.pid, lstart}), {
			mode: 0o600,
		})
		renameSync(temporary, path)
	} catch {
		// Without the record an owner crash makes this attempt uncertain.
	}
}

interface AssistantLike {
	role?: string
	content?: unknown
	stopReason?: string
	errorMessage?: string
}

function lastAssistant(ctx: ExtensionContext): AssistantLike | undefined {
	const branch = ctx.sessionManager.getBranch()
	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index]
		if (entry.type !== 'message') continue
		const message = (entry as {message?: AssistantLike}).message
		if (message?.role === 'assistant') return message
	}
	return undefined
}

function assistantText(message: AssistantLike): string {
	if (typeof message.content === 'string') return message.content
	if (!Array.isArray(message.content)) return ''
	return message.content
		.flatMap((part: {type?: string; text?: unknown}) =>
			part?.type === 'text' && typeof part.text === 'string' ? [part.text] : [],
		)
		.join('\n')
}

function boundedText(text: string, loopId: string): string {
	if (Buffer.byteLength(text, 'utf8') <= MAX_TEXT_BYTES) return text
	const notice = `\n\n[truncated; the full report is in /loop show ${loopId}]`
	return (
		truncateBytes(text, MAX_TEXT_BYTES - Buffer.byteLength(notice, 'utf8')) +
		notice
	)
}

/**
 * The `loop_send` tool's work: a note goes straight into the owner's inbox,
 * at most NOTES_PER_RUN per run, so a runaway run cannot flood the owner.
 */
export function createNoteSender(
	env: NodeJS.ProcessEnv = process.env,
): (text: string) => Promise<string> {
	let sent = 0
	return async (text) => {
		const loopId = env.PI_LOOP_ID ?? ''
		const owner = env.PI_LOOP_OWNER_SESSION_ID ?? ''
		const iteration = Number.parseInt(env.PI_LOOP_ITERATION ?? '', 10)
		const inbox = env.PI_LOOP_INBOX
		if (
			!inbox ||
			!isValidLoopId(loopId) ||
			!isValidSessionId(owner) ||
			!Number.isInteger(iteration)
		)
			throw new Error('loop_send works only inside a loop run.')
		if (sent >= NOTES_PER_RUN)
			throw new Error(
				`This run already sent ${NOTES_PER_RUN} notes; put the rest in the final report.`,
			)
		sent += 1
		const notice = '\n\n[truncated]'
		const body =
			Buffer.byteLength(text, 'utf8') <= MAX_NOTE_BYTES
				? text
				: truncateBytes(
						text,
						MAX_NOTE_BYTES - Buffer.byteLength(notice, 'utf8'),
					) + notice
		await writeInboxMessage(inbox, {
			version: 1,
			id: noteId(loopId, iteration, sent),
			kind: 'note',
			ownerSessionId: owner,
			loopId,
			iteration,
			text: body,
			status: 'completed',
			createdAt: new Date().toISOString(),
		})
		return `Sent note ${sent} of ${NOTES_PER_RUN} to the owner session.`
	}
}

/**
 * Child-side behavior: stop with the owner, and record observability.
 * `exit` is injectable so tests can observe the orphan check. Returns a
 * function that stops the parent watch, or undefined when another load of
 * this extension already registered the child behavior.
 */
export function registerLoopChild(
	pi: ExtensionAPI,
	env: NodeJS.ProcessEnv = process.env,
	exit: (code: number) => never = process.exit,
): (() => void) | undefined {
	// The owner passes this extension explicitly; discovery may load it too.
	const scope = globalThis as unknown as Record<symbol, unknown>
	if (scope[CHILD_GUARD]) return undefined
	scope[CHILD_GUARD] = true
	const loopDir = env.PI_LOOP_DIR as string
	const parent = parseParentPid(env.PI_LOOP_PARENT_PID)
	// A parent that died before this extension loaded has already been
	// replaced by the reaper, so compare with the expected owner, not with
	// whatever process.ppid says now.
	if (parent === undefined || process.ppid !== parent) exit(ORPHANED_EXIT_CODE)
	const iteration = Number.parseInt(env.PI_LOOP_ITERATION ?? '', 10)
	auditIteration = Number.isFinite(iteration) ? iteration : undefined
	if (auditIteration !== undefined) writeSelfRecord(loopDir, auditIteration)
	// A reparent changes process.ppid, so a reused owner PID cannot fool
	// this check. TERM runs Pi's own cleanup of its tracked tool processes.
	const watch = setInterval(() => {
		if (process.ppid === parent) return
		clearInterval(watch)
		process.kill(process.pid, 'SIGTERM')
	}, PARENT_WATCH_MS)
	watch.unref()

	// The structured result the owner publishes to its inbox. Written once,
	// on the first settle: retries and continuations finish before it fires.
	const startedAt = Date.now()
	let reported = false
	pi.on('agent_settled', async (event, ctx) => {
		if (reported) return
		reported = true
		const loopId = env.PI_LOOP_ID ?? ''
		const owner = env.PI_LOOP_OWNER_SESSION_ID ?? ''
		const resultPath = env.PI_LOOP_RESULT
		if (!resultPath || auditIteration === undefined) return
		if (!isValidLoopId(loopId) || !isValidSessionId(owner)) return
		const assistant = lastAssistant(ctx)
		const failed =
			event.aborted ||
			!assistant ||
			assistant.stopReason === 'error' ||
			assistant.stopReason === 'aborted'
		const error = assistant ? assistant.errorMessage : 'no assistant response'
		const message: LoopInboxMessage = {
			version: 1,
			id: reportId(loopId, auditIteration),
			kind: 'report',
			ownerSessionId: owner,
			loopId,
			iteration: auditIteration,
			text: boundedText(assistant ? assistantText(assistant) : '', loopId),
			status: failed ? 'failed' : 'completed',
			error: error ? truncateBytes(error, MAX_ERROR_BYTES) : undefined,
			durationSeconds: Math.round((Date.now() - startedAt) / 1000),
			createdAt: new Date().toISOString(),
		}
		try {
			await writeAtomic(resultPath, `${JSON.stringify(message)}\n`)
		} catch {
			// Without a result the owner publishes a failure report instead.
			return
		}
		// Result first, then the claim: a crash between the two leaves the
		// owner messages for review instead of losing them.
		if (!failed)
			await rm(join(loopDir, FILES.claimed, String(auditIteration)), {
				recursive: true,
				force: true,
			}).catch(() => {})
	})

	const toolStartedAt = new Map<string, number>()
	const audit = (filenames: string[], event: Record<string, unknown>) =>
		appendLoopAudit(loopDir, filenames, event)
	void audit([FILES.events], {
		event: 'child_start',
		pid: process.pid,
		cwd: process.cwd(),
	})
	pi.on('session_start', async (event) => {
		await audit([FILES.events], {event: 'session_start', reason: event.reason})
	})
	pi.on('agent_start', async () => {
		await audit([FILES.events], {event: 'agent_start'})
	})
	pi.on('turn_start', async () => {
		await audit([FILES.events], {event: 'turn_start'})
	})
	pi.on('message_end', async (event) => {
		await audit([FILES.events], {event: 'message_end', message: event.message})
	})
	pi.on('tool_execution_start', async (event) => {
		toolStartedAt.set(event.toolCallId, Date.now())
		await audit([FILES.commands, FILES.events], {
			event: 'tool_start',
			toolCallId: event.toolCallId,
			toolName: event.toolName,
			args: event.args,
		})
	})
	pi.on('tool_execution_end', async (event) => {
		const startedAt = toolStartedAt.get(event.toolCallId)
		toolStartedAt.delete(event.toolCallId)
		await audit([FILES.commands, FILES.events], {
			event: 'tool_end',
			toolCallId: event.toolCallId,
			toolName: event.toolName,
			isError: event.isError,
			durationMs: startedAt ? Date.now() - startedAt : undefined,
			result: event.result,
		})
	})
	pi.on('turn_end', async (event) => {
		await audit([FILES.events], {
			event: 'turn_end',
			toolResultCount: event.toolResults.length,
		})
	})
	pi.on('agent_end', async (event) => {
		await audit([FILES.events], {
			event: 'agent_end',
			messageCount: event.messages.length,
		})
	})
	pi.on('session_shutdown', async () => {
		await audit([FILES.events], {event: 'session_shutdown'})
	})
	return () => clearInterval(watch)
}
