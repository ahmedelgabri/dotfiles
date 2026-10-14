import {
	DEFAULT_INTERVAL_MS,
	INTERVAL_MULTIPLIERS,
	formatDailyTime,
	isValidSchedule,
	type DailySchedule,
	type LoopSchedule,
} from './core.ts'
import type {Delivery} from './inbox.ts'

export const DEFAULT_INTERVAL = '30m'
export const INTERVAL_HINT = 'Use 30s–30d, for example 30m or 2h.'
export const SCHEDULE_HINT =
	'Use 30s–30d or a daily time, for example 30m, daily 09:00, or every day at 9AM.'

export interface ParsedStartArgs {
	schedule: LoopSchedule
	prompt: string
	delivery: Delivery
}

export function parseInterval(value: string): number | undefined {
	const match = value
		.trim()
		.toLowerCase()
		.match(/^(\d+(?:\.\d+)?)(s|m|h|d)$/)
	if (!match) return undefined
	const amount = Number(match[1])
	const intervalMs = Math.round(amount * INTERVAL_MULTIPLIERS[match[2]])
	if (!isValidSchedule({kind: 'interval', intervalMs})) return undefined
	return intervalMs
}

export function parseDailyTime(value: string): DailySchedule | undefined {
	const match = value.trim().match(/^(\d{1,2})(?::(\d{2}))?(AM|PM)?$/i)
	if (!match) return undefined
	let hour = Number(match[1])
	const minute = Number(match[2] ?? 0)
	const meridiem = match[3]?.toUpperCase()
	if (minute > 59) return undefined
	if (meridiem) {
		if (hour < 1 || hour > 12) return undefined
		if (hour === 12) hour = 0
		if (meridiem === 'PM') hour += 12
	} else if (!match[2] || hour > 23) {
		// A bare number is too easy to confuse with the recurring prompt.
		return undefined
	}
	return {kind: 'daily', hour, minute}
}

function unquote(value: string): string {
	if (value.length < 2) return value
	const first = value[0]
	const last = value.at(-1)
	if ((first === '"' && last === '"') || (first === "'" && last === "'"))
		return value.slice(1, -1)
	return value
}

export function parseSchedulePrefix(
	rawArgs: string,
	allowDefault: boolean,
): {schedule: LoopSchedule; rest: string} | {error: string} {
	const rest = rawArgs.trim()
	const daily = rest.match(
		/^(?:daily(?:\s+at)?|every\s+day(?:\s+at)?)\s+(\S+?)(?:\s+(AM|PM)(?=\s|$))?(?=\s|$)/i,
	)
	if (daily) {
		const time = `${daily[1]}${daily[2] ?? ''}`
		const schedule = parseDailyTime(time)
		if (!schedule)
			return {error: `Invalid daily time "${time}". ${SCHEDULE_HINT}`}
		return {schedule, rest: rest.slice(daily[0].length).trimStart()}
	}
	if (/^(?:daily|every\s+day)(?:\s+|$)/i.test(rest))
		return {error: `A valid daily time is required. ${SCHEDULE_HINT}`}

	const firstToken = rest.match(/^(\S+)(?:\s+|$)/)
	if (firstToken) {
		const intervalMs = parseInterval(firstToken[1])
		if (intervalMs !== undefined) {
			return {
				schedule: {kind: 'interval', intervalMs},
				rest: rest.slice(firstToken[0].length).trimStart(),
			}
		}
		if (/^\d/.test(firstToken[1]) && /[smhd]$/i.test(firstToken[1]))
			return {
				error: `Invalid interval "${firstToken[1]}". ${INTERVAL_HINT}`,
			}
	}

	if (!allowDefault) return {error: `Invalid schedule. ${SCHEDULE_HINT}`}
	return {
		schedule: {kind: 'interval', intervalMs: DEFAULT_INTERVAL_MS},
		rest,
	}
}

export function parseStartArgs(
	rawArgs: string,
): ParsedStartArgs | {error: string} {
	let raw = rawArgs.trim()
	if (/^--(?:safe|full)(?:\s+|$)/.test(raw))
		return {error: '--safe/--full were removed; loops use normal Pi tools.'}
	let delivery: Delivery = 'reactive'
	const passive = raw.match(/^--passive(?:\s+|$)/)
	if (passive) {
		delivery = 'passive'
		raw = raw.slice(passive[0].length)
	}
	const flag = raw.match(/^--[a-z][\w-]*(?=\s|$)/)
	if (flag)
		return {error: `Unknown option ${flag[0]}; only --passive is supported.`}

	const parsed = parseSchedulePrefix(raw, true)
	if ('error' in parsed) return parsed
	const prompt = unquote(parsed.rest.trim())
	if (!prompt) return {error: 'A recurring prompt is required.'}
	return {schedule: parsed.schedule, prompt, delivery}
}

export function formatDuration(intervalMs: number): string {
	for (const unit of ['d', 'h', 'm'] as const) {
		if (intervalMs % INTERVAL_MULTIPLIERS[unit] === 0)
			return `${intervalMs / INTERVAL_MULTIPLIERS[unit]}${unit}`
	}
	return `${intervalMs / INTERVAL_MULTIPLIERS.s}s`
}

export function formatSchedule(schedule: LoopSchedule): string {
	return schedule.kind === 'interval'
		? `every ${formatDuration(schedule.intervalMs)}`
		: `daily at ${formatDailyTime(schedule)}`
}

export function formatNextRun(epoch: number | undefined): string | undefined {
	if (!epoch) return undefined
	const remaining = epoch * 1000 - Date.now()
	if (remaining <= 0) return 'due'
	if (remaining < INTERVAL_MULTIPLIERS.m)
		return `in ${Math.ceil(remaining / INTERVAL_MULTIPLIERS.s)}s`
	if (remaining < INTERVAL_MULTIPLIERS.h)
		return `in ${Math.ceil(remaining / INTERVAL_MULTIPLIERS.m)}m`
	return `in ${Math.ceil(remaining / INTERVAL_MULTIPLIERS.h)}h`
}

export function oneLine(value: string): string {
	return value.replace(/\s+/g, ' ').trim()
}
