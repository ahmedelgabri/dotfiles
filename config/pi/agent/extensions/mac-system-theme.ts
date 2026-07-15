/**
 * Syncs pi theme with macOS system appearance (dark/light mode).
 *
 * Usage:
 *   pi -e examples/extensions/mac-system-theme.ts
 */

import {exec} from 'node:child_process'
import {promisify} from 'node:util'
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

const execAsync = promisify(exec)

async function isDarkMode(): Promise<boolean> {
	// `defaults read` avoids spawning AppleScript/System Events on every poll,
	// which would otherwise trigger TCC automation checks and drain battery.
	// The key is absent (command exits non-zero) in light mode, hence the catch.
	try {
		const {stdout} = await execAsync('defaults read -g AppleInterfaceStyle')
		return stdout.trim() === 'Dark'
	} catch {
		return false
	}
}

// Custom plain themes from config/pi/agent/themes; the built-in names are the
// fallback for machines where those themes are not on the theme path.
const THEME_BY_MODE = {
	dark: 'plain-dark',
	light: 'plain-light',
} as const

function applyTheme(ctx: {ui: {setTheme: (theme: string) => void}}, mode: 'dark' | 'light') {
	try {
		ctx.ui.setTheme(THEME_BY_MODE[mode])
	} catch {
		ctx.ui.setTheme(mode)
	}
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null

	pi.on('session_start', async (_event, ctx) => {
		let currentMode: 'dark' | 'light' = (await isDarkMode()) ? 'dark' : 'light'
		applyTheme(ctx, currentMode)

		intervalId = setInterval(async () => {
			const newMode = (await isDarkMode()) ? 'dark' : 'light'
			if (newMode !== currentMode) {
				currentMode = newMode
				applyTheme(ctx, currentMode)
			}
		}, 5000)
	})

	pi.on('session_shutdown', () => {
		if (intervalId) {
			clearInterval(intervalId)
			intervalId = null
		}
	})
}
