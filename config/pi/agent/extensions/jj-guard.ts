/**
 * Jujutsu Guard Extension
 *
 * Blocks raw `git add`, `git stage`, and `git commit` commands when
 * running inside a Jujutsu repository. These operations should go
 * through `jj` instead.
 */

import type {ExtensionAPI} from '@mariozechner/pi-coding-agent'
import {isToolCallEventType} from '@mariozechner/pi-coding-agent'

// Not a security boundary — just a heuristic to catch the most common
// forms of `git add`, `git stage`, `git history` and `git commit` that an LLM agent
// is likely to produce. Won't catch every possible invocation (eg.
// `env A=1 git commit`) but covers the reasonable cases.
const BLOCKED_PATTERNS = [
	/(?:^|[;&|]\s*)git\b.+\badd\b/,
	/(?:^|[;&|]\s*)git\b.+\bstage\b/,
	/(?:^|[;&|]\s*)git\b.+\bhistory\b/,
	/(?:^|[;&|]\s*)git\b.+\bcommit\b/,
]

const JUJUTSU_REPO_INSTRUCTION =
	'This repository uses Jujutsu (`jj`). Avoid raw `git add`, `git stage`, `git history`, and `git commit`. Use `jj` commands instead for repository-changing workflows.'

async function isJujutsuRepo(pi: ExtensionAPI): Promise<boolean> {
	try {
		const {code} = await pi.exec('jj', ['--ignore-working-copy', 'root'])
		return code === 0
	} catch {
		return false
	}
}

export default function (pi: ExtensionAPI) {
	pi.on('before_agent_start', async (event) => {
		if (!(await isJujutsuRepo(pi))) {
			return
		}

		return {
			systemPrompt: `${event.systemPrompt}\n\n${JUJUTSU_REPO_INSTRUCTION}`,
		}
	})

	pi.on('tool_call', async (event) => {
		if (!isToolCallEventType('bash', event)) {
			return
		}

		const command = event.input.command
		if (!BLOCKED_PATTERNS.some((pattern) => pattern.test(command))) {
			return
		}

		if (!(await isJujutsuRepo(pi))) {
			return
		}

		return {
			block: true,
			reason:
				'This is a Jujutsu repository. Use `jj` commands instead of raw git add/stage/commit/history.',
		}
	})
}
