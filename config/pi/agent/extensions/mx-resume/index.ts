import {mkdir, writeFile} from 'node:fs/promises'
import {dirname} from 'node:path'
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

function shellQuote(value: string): string {
	return `'${value.replaceAll("'", `'\\''`)}'`
}

export default function (pi: ExtensionAPI) {
	const file = process.env._MX_RESUME_FILE
	// Pi processes that tools or other agents start inherit the variable too,
	// but only the one the pane's shell started owns the pane.
	if (!file || String(process.ppid) !== process.env._MX_SHELL_PID) return

	pi.on('session_start', async (_event, ctx) => {
		// `--no-session` keeps nothing to resume.
		if (!ctx.sessionManager.getSessionFile()) return
		// Pi writes the session file only after the first message, so
		// `--session <file>` would fail for a session that got none.
		// `--session-id` opens it when it exists and starts it otherwise.
		const id = ctx.sessionManager.getSessionId()
		await mkdir(dirname(file), {recursive: true})
		await writeFile(
			file,
			`cd -- ${shellQuote(ctx.cwd)} && pi --session-id ${shellQuote(id)}\n`,
		)
	})
}
