import {watch, type FSWatcher} from 'node:fs'
import {mkdir} from 'node:fs/promises'
import {performance} from 'node:perf_hooks'
import type {
	ExtensionAPI,
	ExtensionContext,
	TurnEndEvent,
	TurnEndEventResult,
} from '@earendil-works/pi-coding-agent'
import {readOptional} from './core.ts'
import {
	buildBatch,
	detailsOf,
	INBOX_CUSTOM_TYPE,
	inboxPaths,
	noteDelivery,
	parseInboxId,
	parseSessionRecords,
	quarantine,
	readPending,
	removePending,
	renderContent,
	type Batch,
	type Delivery,
	type InboxDetails,
	type InboxPaths,
	type LoopInboxMessage,
	type RecordedDeliveries,
} from './inbox.ts'
import type {SessionRuntime} from './runtime.ts'

const POLL_MS = 5000
const DEBOUNCE_MS = 100
const STUCK_MS = 2 * 60 * 1000

export interface Submission {
	seq: number
	submittedMono: number
	coveredIds: string[]
	fullReports: Array<{loopId: string; iteration: number}>
}

export async function recordedDeliveries(
	sessionFile: string | undefined,
): Promise<RecordedDeliveries> {
	const content = sessionFile ? await readOptional(sessionFile) : undefined
	return parseSessionRecords(content ?? '')
}

/** In-memory entries; recorded is not durable until the disk scan sees it. */
function liveDeliveries(ctx: ExtensionContext): RecordedDeliveries {
	const live: RecordedDeliveries = {ids: new Set(), maxFull: new Map()}
	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type !== 'custom_message') continue
		const custom = entry as {customType?: string; details?: unknown}
		if (custom.customType !== INBOX_CUSTOM_TYPE) continue
		noteDelivery(live, custom.details as Partial<InboxDetails> | undefined)
	}
	return live
}

export interface ReceiverHost {
	pi: ExtensionAPI
	rt: SessionRuntime
	isActive(): boolean
	modeOf(loopId: string): Delivery
	// A non-reload start runs in a new AgentSession, whose private queue
	// cannot hold anything an earlier one was sent.
	resetSubmissions: boolean
}

/**
 * Moves inbox files into the session. A file is deleted only after its ID
 * appears in a complete record of the session file on disk. Sends happen
 * only while the agent is idle, except passive reports, which are proposed
 * as turn_end drafts that Pi commits at the end of the current turn.
 */
export class Receiver {
	private readonly host: ReceiverHost
	private readonly paths: InboxPaths
	private watcher?: FSWatcher
	private timer?: NodeJS.Timeout
	private debounce?: NodeJS.Timeout
	private running?: Promise<void>
	private again = false
	private stopped = false
	private resetPending: boolean
	private readonly seen = new Set<string>()
	private readonly stuckNotified = new Set<number>()
	private snapshot: LoopInboxMessage[] = []
	private recorded: RecordedDeliveries = {ids: new Set(), maxFull: new Map()}
	ctx: ExtensionContext

	constructor(host: ReceiverHost, ctx: ExtensionContext) {
		this.host = host
		this.ctx = ctx
		this.resetPending = host.resetSubmissions
		const paths = inboxPaths(host.rt.root, host.rt.sessionId)
		if (!paths) throw new Error(`Invalid session ID: ${host.rt.sessionId}`)
		this.paths = paths
	}

	/** The inbox directories, without the watcher and the timer. */
	async prepare(): Promise<void> {
		await mkdir(this.paths.pending, {recursive: true, mode: 0o700})
		await mkdir(this.paths.rejected, {recursive: true, mode: 0o700})
	}

	async start(): Promise<void> {
		await this.prepare()
		try {
			this.watcher = watch(this.paths.pending, () => this.schedule())
			this.watcher.on('error', () => this.watcherFailed())
		} catch {
			this.watcherFailed()
		}
		this.timer = setInterval(() => this.schedule(), POLL_MS)
		this.timer.unref()
		this.schedule(0)
	}

	private watcherFailed(): void {
		this.watcher?.close()
		this.watcher = undefined
		this.notify(
			'Loop inbox: file watching is unavailable, so new reports can take up to 5 seconds to appear.',
			'warning',
		)
	}

	/** Synchronous: after this returns, nothing of this receiver sends. */
	stop(): Promise<void> {
		this.stopped = true
		this.watcher?.close()
		this.watcher = undefined
		if (this.timer) clearInterval(this.timer)
		if (this.debounce) clearTimeout(this.debounce)
		this.timer = undefined
		this.debounce = undefined
		return this.running ?? Promise.resolve()
	}

	private active(): boolean {
		return !this.stopped && this.host.isActive()
	}

	private notify(message: string, type: 'info' | 'warning' | 'error'): void {
		if (this.active()) this.ctx.ui.notify(message, type)
	}

	schedule(delay = DEBOUNCE_MS): void {
		if (!this.active()) return
		if (this.debounce) clearTimeout(this.debounce)
		this.debounce = setTimeout(() => {
			this.debounce = undefined
			void this.drain()
		}, delay)
		this.debounce.unref()
	}

	/** Serialized: a wake during a drain schedules exactly one more. */
	drain(): Promise<void> {
		if (this.running) {
			this.again = true
			return this.running
		}
		this.running = (async () => {
			try {
				do {
					this.again = false
					await this.drainOnce()
				} while (this.again && this.active())
			} catch (error) {
				this.notify(
					`Loop inbox: ${error instanceof Error ? error.message : String(error)}`,
					'error',
				)
			} finally {
				this.running = undefined
			}
		})()
		return this.running
	}

	private covered(): Set<string> {
		return new Set(
			this.host.rt.submissions.flatMap((submission) => submission.coveredIds),
		)
	}

	private held(): Set<string> {
		const loops = new Set<string>()
		for (const id of this.covered()) {
			const parsed = parseInboxId(id)
			if (parsed?.kind === 'report') loops.add(parsed.loopId)
		}
		return loops
	}

	private maxFull(live: RecordedDeliveries): Map<string, number> {
		const merged = new Map(this.recorded.maxFull)
		for (const [loopId, iteration] of live.maxFull)
			merged.set(loopId, Math.max(merged.get(loopId) ?? 0, iteration))
		for (const submission of this.host.rt.submissions)
			for (const {loopId, iteration} of submission.fullReports)
				merged.set(loopId, Math.max(merged.get(loopId) ?? 0, iteration))
		return merged
	}

	private eligible(live: RecordedDeliveries): LoopInboxMessage[] {
		const covered = this.covered()
		return this.snapshot.filter(
			(message) => !live.ids.has(message.id) && !covered.has(message.id),
		)
	}

	private batch(live: RecordedDeliveries, only?: Delivery): Batch | undefined {
		return buildBatch(this.eligible(live), {
			maxFull: this.maxFull(live),
			held: this.held(),
			modeOf: (loopId) => this.host.modeOf(loopId),
			only,
		})
	}

	private async drainOnce(): Promise<void> {
		if (!this.active()) return
		const rt = this.host.rt
		const pending = await readPending(this.paths, rt.sessionId)
		if (!this.active()) return
		if (pending.length === 0 && rt.submissions.length === 0) {
			this.snapshot = []
			return
		}

		this.recorded = await recordedDeliveries(rt.sessionFile)
		if (!this.active()) return
		const valid: LoopInboxMessage[] = []
		for (const file of pending) {
			if (!file.message) {
				if (file.error === 'disappeared') continue
				await quarantine(this.paths, file.file).catch(() => {})
				this.notify(
					`Loop inbox: moved ${file.file} to rejected/ (${file.error}).`,
					'warning',
				)
				continue
			}
			if (this.recorded.ids.has(file.message.id)) {
				await removePending(this.paths, file.file)
				continue
			}
			valid.push(file.message)
		}
		rt.submissions = rt.submissions.filter(
			(submission) =>
				!submission.coveredIds.every((id) => this.recorded.ids.has(id)),
		)
		if (this.resetPending) {
			rt.submissions = []
			this.resetPending = false
		}
		this.snapshot = valid
		if (!this.active()) return

		const idle = this.ctx.isIdle()
		for (const message of valid) {
			if (this.seen.has(message.id)) continue
			this.seen.add(message.id)
			const mode = this.host.modeOf(message.loopId)
			const when = idle
				? 'arriving now'
				: mode === 'reactive'
					? 'the agent reacts after this run'
					: 'enters context after this turn'
			this.notify(
				`↻ Loop ${message.loopId} #${message.iteration} ${message.kind} · ${when}`,
				'info',
			)
		}
		const now = performance.now()
		for (const submission of rt.submissions)
			if (
				now - submission.submittedMono > STUCK_MS &&
				!this.stuckNotified.has(submission.seq)
			) {
				this.stuckNotified.add(submission.seq)
				this.notify(
					'A loop report may be stuck; it is retried when this session next starts.',
					'warning',
				)
			}

		if (!this.ctx.isIdle()) return
		const live = liveDeliveries(this.ctx)
		const batch = this.batch(live)
		if (!batch) return
		// No await from here to the send: idle and generation are current.
		if (!this.active() || !this.ctx.isIdle()) return
		this.send(batch)
	}

	private send(batch: Batch): void {
		const message = {
			customType: INBOX_CUSTOM_TYPE,
			content: renderContent(batch.items),
			display: true,
			details: detailsOf(batch.items),
		}
		if (batch.mode === 'reactive') {
			const rt = this.host.rt
			rt.seq += 1
			rt.submissions.push({
				seq: rt.seq,
				submittedMono: performance.now(),
				coveredIds: [...batch.messageIds, ...batch.supersededIds],
				fullReports: batch.fullReports,
			})
			this.host.pi.sendMessage(message, {
				triggerTurn: true,
				deliverAs: 'followUp',
			})
		} else {
			this.host.pi.sendMessage(message, {triggerTurn: false})
		}
	}

	pendingFor(loopId: string): number {
		return this.snapshot.filter((message) => message.loopId === loopId).length
	}

	/** Busy passive delivery: Pi commits these drafts after all handlers. */
	turnEnd(
		event: TurnEndEvent,
		ctx: ExtensionContext,
	): TurnEndEventResult | undefined {
		if (!this.active()) return undefined
		const batch = this.batch(liveDeliveries(ctx), 'passive')
		if (!batch) return undefined
		return {
			entries: [
				...event.entries,
				{
					type: 'custom_message',
					customType: INBOX_CUSTOM_TYPE,
					content: renderContent(batch.items),
					display: true,
					details: detailsOf(batch.items),
				},
			],
		}
	}
}
