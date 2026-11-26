import {spawn} from 'node:child_process'
import {closeSync, openSync} from 'node:fs'
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

export default function (pi: ExtensionAPI) {
	const token = process.env.OSC7577_TOKEN
	if (!token) return
	// A program that reports removes the token from what it starts, so pi
	// processes that tools or other agents start, such as `/loop` runs, cannot
	// take over the pane.
	delete process.env.OSC7577_TOKEN

	pi.on('session_start', async (_event, ctx) => {
		// `--no-session` keeps nothing to resume.
		if (!ctx.sessionManager.getSessionFile()) return
		// Pi writes the session file only after the first message, so
		// `--session <file>` would fail for a session that got none.
		// `--session-id` opens it when it exists and starts it otherwise.
		const id = ctx.sessionManager.getSessionId()
		let tty: number
		try {
			tty = openSync('/dev/tty', 'w')
		} catch {
			return
		}
		try {
			const child = spawn(
				'resume-report',
				[String(process.pid), ctx.cwd, 'pi', '--session-id', id],
				{
					env: {...process.env, OSC7577_TOKEN: token},
					stdio: ['ignore', tty, 'ignore'],
				},
			)
			await new Promise((resolve) => {
				child.on('error', resolve)
				child.on('close', resolve)
			})
		} finally {
			closeSync(tty)
		}
	})
}
