/**
 * Headless mode
 *
 * Print and JSON runs (`pi -p`, `/loop` iterations, `/simplify` reviewers)
 * have nobody to answer a question, so an agent that asks one stalls and
 * the run is wasted. Without a UI, add instructions to decide and proceed.
 *
 * Adapted from https://github.com/megalithic/dotfiles/blob/a64a8173b4d6f5edb3ee17e7efb8a56e905dd8e2/config/pi-coding-agent/agent/extensions/non-interactive.ts
 */

import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

export const HEADLESS_SECTION = 'headless'

export const HEADLESS_INSTRUCTIONS = `This run has no interactive UI. Nobody can answer questions or provide more input until it ends.

- Never ask clarifying questions. Make reasonable assumptions, state them, and proceed.
- Do not end with offers or requests for input, such as "Would you like me to..." or "Let me know if...".
- Report what you did, not what you could do.
- If you are blocked, explain the blocker in your final response and stop.`

export default function (pi: ExtensionAPI) {
	pi.on('before_agent_start', (event, ctx) => {
		if (ctx.hasUI) return

		// A returned systemPrompt would replace the whole prompt and drop
		// sections and guidelines that later extensions add.
		event.systemPromptOptions.sections[HEADLESS_SECTION] = HEADLESS_INSTRUCTIONS
	})
}
