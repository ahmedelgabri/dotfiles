/**
 * Agent history extension for pi.
 *
 * Records commands executed by pi's bash tool in the agent-only history file
 * through `agent-history record pi` (config/zsh.d/zsh/bin), the same writer the
 * Claude Code and Codex hooks use. Listening on `tool_result` mirrors those
 * PostToolUse hooks: pi only emits it for calls that actually executed, so
 * blocked and aborted-before-spawn calls are never recorded, while commands
 * that ran and failed are.
 */

import {spawn} from 'node:child_process'
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

const RECORD_TIMEOUT_MS = 10_000

// Resolves with the recorder's stderr when it fails, so the caller can surface
// the message without ever rejecting: recording must not affect the tool.
function record(
	cwd: string,
	command: string,
	sessionId: string,
): Promise<string | undefined> {
	return new Promise((resolve) => {
		let stderr = ''
		let child
		try {
			child = spawn('agent-history', ['record', 'pi'], {
				cwd,
				stdio: ['pipe', 'ignore', 'pipe'],
				timeout: RECORD_TIMEOUT_MS,
			})
		} catch (error) {
			resolve(String(error))
			return
		}
		child.on('error', (error) => resolve(error.message))
		child.stderr.on('data', (chunk: Buffer | string) => {
			stderr += chunk.toString()
		})
		child.on('close', (code) => {
			resolve(code === 0 ? undefined : stderr.trim() || `exit ${code}`)
		})
		// The recorder may exit before reading stdin (usage error), which
		// would otherwise surface as an unhandled EPIPE.
		child.stdin.on('error', () => {})
		child.stdin.end(
			JSON.stringify({
				tool_name: 'Bash',
				tool_input: {command},
				cwd,
				session_id: sessionId,
			}),
		)
	})
}

export default function (pi: ExtensionAPI) {
	pi.on('tool_result', async (event, ctx) => {
		if (event.toolName !== 'bash') return

		const command = event.input.command
		if (typeof command !== 'string' || command.length === 0) return

		const failure = await record(
			ctx.cwd,
			command,
			ctx.sessionManager.getSessionId(),
		)
		if (failure) ctx.ui.notify(`agent-history: ${failure}`, 'warning')
	})
}
