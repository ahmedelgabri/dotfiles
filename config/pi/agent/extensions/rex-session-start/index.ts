/**
 * Rex session start
 *
 * Rex tells Claude Code and Codex at session start which Rex session and pane
 * they run in, through a SessionStart hook that `rex skill setup` installs.
 * Pi has no command hooks, so setup skips it. This extension adds the same
 * text, from the same command, as a system prompt section.
 */

import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

export const REX_SECTION = 'rex'

// The same flags as the Rex hooks in config/claude/settings.json and
// config/codex/hooks.json.
export const REX_COMMAND = [
	'__internal',
	'session-start',
	'--agent',
	'pi',
	'--feature-session-naming=false',
]

export default function (pi: ExtensionAPI) {
	let context = ''

	pi.on('session_start', async () => {
		// Outside a Rex pane the command prints nothing. A missing or failing
		// rex leaves the prompt without the section, as the hooks' `|| true`
		// does for the other agents.
		try {
			const result = await pi.exec('rex', REX_COMMAND, {timeout: 5000})
			context = result.code === 0 ? result.stdout.trim() : ''
		} catch {
			context = ''
		}
	})

	pi.on('before_agent_start', (event) => {
		if (!context) return
		// A returned systemPrompt would replace the whole prompt and drop
		// sections and guidelines that later extensions add.
		event.systemPromptOptions.sections[REX_SECTION] = context
	})
}
