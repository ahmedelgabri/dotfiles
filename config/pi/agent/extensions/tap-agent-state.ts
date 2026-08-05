// Managed by tap (tmux-agent-panel). `tap uninstall` removes this file;
// local edits will be overwritten by the next `tap install`.
//
// Delegates state reporting to `tap state` (invoked from PATH), the same
// writer the Claude Code and Codex hooks use, so the pane-option protocol
// has a single implementation. tap itself no-ops outside tmux; the guard
// here only avoids pointless spawns.
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

export default function (pi: ExtensionAPI) {
	if (!process.env.TMUX || !process.env.TMUX_PANE) return

	async function tapState(args: string[]): Promise<void> {
		try {
			await pi.exec('tap', ['state', ...args])
		} catch {}
	}

	pi.on('session_start', async () => {
		await tapState(['idle'])
	})

	pi.on('before_agent_start', async (event) => {
		await tapState(['running', '--title', event.prompt])
	})

	pi.on('agent_start', async () => {
		await tapState(['running'])
	})

	pi.on('agent_settled', async () => {
		await tapState(['idle'])
	})

	pi.on('session_shutdown', async () => {
		await tapState(['clear'])
	})
}
