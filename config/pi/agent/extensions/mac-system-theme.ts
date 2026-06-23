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

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null

	pi.on('session_start', async (_event, ctx) => {
		let currentTheme = (await isDarkMode()) ? 'dark' : 'light'
		ctx.ui.setTheme(currentTheme)

		intervalId = setInterval(async () => {
			const newTheme = (await isDarkMode()) ? 'dark' : 'light'
			if (newTheme !== currentTheme) {
				currentTheme = newTheme
				ctx.ui.setTheme(currentTheme)
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
