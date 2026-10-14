import type {BatchItem} from './inbox.ts'

/**
 * The rendering primitives a card needs. Pi supplies them from pi-tui and
 * the active theme; tests supply plain-text versions.
 */
export interface CardTools {
	fg(color: string, text: string): string
	bold(text: string): string
	markdown(text: string, width: number): string[]
	truncate(text: string, width: number): string
	width(text: string): number
}

export function topBorder(
	label: string,
	width: number,
	tools: CardTools,
): string {
	const border = (text: string) => tools.fg('borderMuted', text)
	const clipped = tools.truncate(` ${label} `, Math.max(1, width - 4))
	const fill = '─'.repeat(Math.max(1, width - tools.width(clipped) - 3))
	return `${border('╭─')}${clipped}${border(`${fill}╮`)}`
}

/** A bordered box; shared by the loop panel and the transcript cards. */
export function boxLines(
	label: string,
	lines: string[],
	width: number,
	tools: CardTools,
): string[] {
	if (width < 8)
		return [label, ...lines].map((line) => tools.truncate(line, width))
	const border = (text: string) => tools.fg('borderMuted', text)
	const inner = Math.max(1, width - 4)
	const body = lines.map((line) => {
		const clipped = tools.truncate(line, inner)
		const pad = ' '.repeat(Math.max(0, inner - tools.width(clipped)))
		return `${border('│')} ${clipped}${pad} ${border('│')}`
	})
	return [
		topBorder(label, width, tools),
		...body,
		border(`╰${'─'.repeat(width - 2)}╯`),
	]
}

function clock(iso: string | undefined): string | undefined {
	if (!iso) return undefined
	const date = new Date(iso)
	if (Number.isNaN(date.getTime())) return undefined
	return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
}

export interface CardOptions {
	// Reports from before the inbox were display-only entries; they never
	// reached the model context.
	displayOnly?: boolean
}

function deliveryLabel(item: BatchItem, options: CardOptions): string {
	if (options.displayOnly) return 'display only'
	return item.delivery === 'reactive' ? 'agent reacting' : 'in context'
}

function digestLines(item: BatchItem, tools: CardTools): string[] {
	return item.digest.map(
		(line) =>
			`${line.status === 'failed' ? tools.fg('error', '✗') : tools.fg('success', '✓')} #${line.iteration} ${clock(line.createdAt) ?? ''} — ${line.headline}`,
	)
}

/** One card per item. The framing sentence is for the model only. */
export function itemCard(
	item: BatchItem,
	options: CardOptions,
	width: number,
	tools: CardTools,
): string[] {
	const inner = Math.max(1, width - 4)
	const untrusted = tools.fg('dim', 'untrusted')
	if (item.kind === 'digest') {
		const title = tools.fg(
			'accent',
			tools.bold(`↻ loop ${item.loopId} · ${item.digest.length} earlier runs`),
		)
		return boxLines(
			title,
			[
				`${tools.fg('muted', deliveryLabel(item, options))} · ${untrusted}`,
				...digestLines(item, tools),
			],
			width,
			tools,
		)
	}
	const icon = item.kind === 'note' ? '✉' : '↻'
	const title = tools.fg(
		'accent',
		tools.bold(`${icon} ${item.loopId} · #${item.iteration} · ${item.kind}`),
	)
	const failed = item.status === 'failed'
	const status = [
		failed ? tools.fg('error', '✗') : tools.fg('success', '✓'),
		...(item.exitCode !== undefined ? [`exit ${item.exitCode}`] : []),
		...(item.durationSeconds !== undefined ? [`${item.durationSeconds}s`] : []),
		...(clock(item.createdAt) ? [clock(item.createdAt) as string] : []),
		deliveryLabel(item, options),
		untrusted,
		...(item.truncated ? [tools.fg('warning', 'truncated')] : []),
	].join(tools.fg('dim', ' · '))
	const lines = [status]
	if (item.needsReview)
		lines.push(
			tools.fg(
				'warning',
				`${item.needsReview} need review · /loop requeue ${item.loopId}`,
			),
		)
	if (item.digest.length > 0) {
		lines.push(
			tools.fg('muted', `${item.digest.length} missed runs`),
			...digestLines(item, tools),
		)
	}
	const text =
		failed && !item.text?.trim()
			? `The run ended before it reported${item.exitCode !== undefined ? ` (exit ${item.exitCode})` : ''}.`
			: (item.text ?? '')
	const body = tools.markdown(
		failed && item.error ? `${text}\n\nError: ${item.error}` : text,
		inner,
	)
	lines.push('', ...body)
	return boxLines(title, lines, width, tools)
}

export function cardLines(
	items: BatchItem[],
	options: CardOptions,
	width: number,
	tools: CardTools,
): string[] {
	return items.flatMap((item, index) => [
		...(index > 0 ? [''] : []),
		...itemCard(item, options, width, tools),
	])
}

export interface ReportHeader {
	iteration?: number
	exitCode?: number
	durationSeconds?: number
	finishedAt?: string
	body: string
}

/** Reads the header that every loop report starts with. */
export function parseReportHeader(report: string): ReportHeader {
	const header: ReportHeader = {body: report}
	const iteration = report.match(/^# Pi loop \S+ — iteration (\d+)$/m)
	if (iteration) header.iteration = Number(iteration[1])
	const exit = report.match(/^- Exit code: (-?\d+)$/m)
	if (exit) header.exitCode = Number(exit[1])
	const duration = report.match(/^- Duration: (\d+)s$/m)
	if (duration) header.durationSeconds = Number(duration[1])
	const finished = report.match(/^- Finished: (.+)$/m)
	if (finished) header.finishedAt = finished[1]
	const end = report.search(/^- (?:Exit code|Error): .*$/m)
	if (end >= 0) {
		const afterLine = report.indexOf('\n', end)
		header.body =
			afterLine >= 0 ? report.slice(afterLine + 1).replace(/^\n/, '') : ''
	}
	return header
}

/** Old display-only report entries rendered with the same card. */
export function legacyReportItem(data: {
	loopId: string
	iteration: number
	report: string
	finishedAt: string
}): BatchItem {
	const header = parseReportHeader(data.report)
	return {
		kind: 'report',
		loopId: data.loopId,
		messageIds: [],
		supersededIds: [],
		delivery: 'passive',
		digest: [],
		truncated: false,
		iteration: data.iteration,
		status:
			header.exitCode === undefined || header.exitCode === 0
				? 'completed'
				: 'failed',
		text: header.body,
		exitCode: header.exitCode,
		durationSeconds: header.durationSeconds,
		createdAt: header.finishedAt ?? data.finishedAt,
	}
}
