import {mkdir, readFile, rename, writeFile} from 'node:fs/promises'
import {homedir} from 'node:os'
import {dirname, join} from 'node:path'

export interface UiPrefs {
	leftSidebarWidth: number
	rightSidebarWidth: number
}

// Kept in sync with MIN/MAX_SIDEBAR_WIDTH in client.js.
const MIN_SIDEBAR_WIDTH = 220
const MAX_SIDEBAR_WIDTH = 720

const DEFAULT_PREFS: UiPrefs = {
	leftSidebarWidth: 280,
	rightSidebarWidth: 340,
}

const getPiAgentDir = (): string =>
	process.env.PI_CODING_AGENT_DIR?.trim() || join(homedir(), '.pi', 'agent')

const getPrefsPath = (): string =>
	process.env.PI_DIFF_PREFS_PATH?.trim() ||
	join(getPiAgentDir(), 'diff', 'ui-prefs.json')

const clampWidth = (value: unknown, fallback: number): number => {
	const numberValue = typeof value === 'number' ? value : Number(value)
	if (!Number.isFinite(numberValue)) return fallback
	return Math.min(
		MAX_SIDEBAR_WIDTH,
		Math.max(MIN_SIDEBAR_WIDTH, Math.round(numberValue)),
	)
}

export const coerceUiPrefs = (value: unknown): UiPrefs => {
	const record =
		value && typeof value === 'object' ? (value as Record<string, unknown>) : {}
	return {
		leftSidebarWidth: clampWidth(
			record.leftSidebarWidth,
			DEFAULT_PREFS.leftSidebarWidth,
		),
		rightSidebarWidth: clampWidth(
			record.rightSidebarWidth,
			DEFAULT_PREFS.rightSidebarWidth,
		),
	}
}

export const loadUiPrefs = async (): Promise<UiPrefs> => {
	try {
		const raw = await readFile(getPrefsPath(), 'utf8')
		return coerceUiPrefs(JSON.parse(raw))
	} catch {
		return {...DEFAULT_PREFS}
	}
}

export const saveUiPrefs = async (value: unknown): Promise<UiPrefs> => {
	const prefs = coerceUiPrefs(value)
	const path = getPrefsPath()
	await mkdir(dirname(path), {recursive: true})
	const tmpPath = `${path}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`
	await writeFile(tmpPath, JSON.stringify(prefs, null, 2) + '\n', 'utf8')
	await rename(tmpPath, path)
	return prefs
}
