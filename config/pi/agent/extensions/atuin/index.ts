/**
 * Atuin extension for pi.
 *
 * Tracks bash commands executed by pi in Atuin history with author `pi`.
 * Kept here instead of using `atuin hook install pi` because this setup moves
 * pi's agent directory from ~/.pi/agent to $PI_CODING_AGENT_DIR.
 */

import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

const ATUIN_AUTHOR = 'pi'
const ATUIN_TIMEOUT_MS = 10_000

async function startHistory(
	pi: ExtensionAPI,
	cwd: string,
	command: string,
): Promise<string | undefined> {
	try {
		const result = await pi.exec(
			'atuin',
			[
				'history',
				'start',
				'--author',
				ATUIN_AUTHOR,
				'--author-kind',
				'agent',
				'--',
				command,
			],
			{cwd, timeout: ATUIN_TIMEOUT_MS},
		)

		if (result.code !== 0) return undefined

		const id = result.stdout.trim()
		return id.length > 0 ? id : undefined
	} catch {
		return undefined
	}
}

async function endHistory(
	pi: ExtensionAPI,
	cwd: string,
	historyId: string,
	exitCode: number,
): Promise<void> {
	try {
		await pi.exec(
			'atuin',
			['history', 'end', historyId, '--exit', String(exitCode)],
			{cwd, timeout: ATUIN_TIMEOUT_MS},
		)
	} catch {
		// Atuin failures must not block command execution.
	}
}

// The bash tool reports failures by appending a status line to the result text
// rather than exposing a numeric exit code, so recover it from there.
function exitCodeFromResult(result: unknown, isError: boolean): number {
	if (!isError) return 0

	const content = (result as {content?: unknown} | undefined)?.content
	const text = Array.isArray(content)
		? content
				.map((part) => {
					const value = (part as {text?: unknown} | undefined)?.text
					return typeof value === 'string' ? value : ''
				})
				.join('\n')
		: ''

	const exited = text.match(/Command exited with code (\d+)\s*$/)
	if (exited) return Number(exited[1])
	if (/Command aborted\s*$/.test(text)) return 130
	if (/Command timed out after \S+ seconds\s*$/.test(text)) return 124
	return 1
}

export default function (pi: ExtensionAPI) {
	const pending = new Map<string, string>()

	// Events observe whichever extension provides the bash tool, unlike
	// registering another bash tool and replacing sandboxes or remote runners.
	pi.on('tool_call', async (event, ctx) => {
		if (event.toolName !== 'bash') return

		const command = (event.input as {command?: unknown}).command
		if (typeof command !== 'string' || command.length === 0) return

		const historyId = await startHistory(pi, ctx.cwd, command)
		if (historyId) pending.set(event.toolCallId, historyId)
	})

	// This event also fires when another extension blocks the call, which keeps
	// every history entry opened above paired with an end event.
	pi.on('tool_execution_end', async (event, ctx) => {
		const historyId = pending.get(event.toolCallId)
		if (!historyId) return
		pending.delete(event.toolCallId)

		await endHistory(
			pi,
			ctx.cwd,
			historyId,
			exitCodeFromResult(event.result, event.isError),
		)
	})
}
