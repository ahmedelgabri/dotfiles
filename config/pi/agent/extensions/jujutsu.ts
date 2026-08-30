/**
 * Jujutsu Extension
 *
 * Shows the working-copy change in the footer and blocks selected Git commands
 * that agents should replace with `jj` equivalents.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from '@earendil-works/pi-coding-agent'
import {isToolCallEventType} from '@earendil-works/pi-coding-agent'
import {
	existsSync,
	readFileSync,
	statSync,
	watch,
	type FSWatcher,
} from 'node:fs'
import {dirname, join, resolve} from 'node:path'

// This is a guardrail rather than a security boundary. It catches the common
// command forms an agent is likely to produce without parsing shell syntax.
const BLOCKED_PATTERNS = [
	/(?:^|[;&|]\s*)git\b.+\badd\b/,
	/(?:^|[;&|]\s*)git\b.+\bstage\b/,
	/(?:^|[;&|]\s*)git\b.+\bhistory\b/,
	/(?:^|[;&|]\s*)git\b.+\bcommit\b/,
]

const JUJUTSU_REPO_INSTRUCTION =
	'This repository uses Jujutsu (`jj`). Avoid raw `git add`, `git stage`, `git history`, and `git commit`. Use `jj` commands instead for repository-changing workflows.'
const STATUS_KEY = 'jujutsu'
// `prompt_revs()` and `prompt_fields()` are aliases in the jj config, shared
// with the shell prompt and the Claude Code statusline so all three render
// the same data.
const STATUS_REVSET = 'prompt_revs()'
const STATUS_TEMPLATE = 'prompt_fields()'
const STATUS_REFRESH_DEBOUNCE_MS = 100

interface StatusFields {
	change: string
	dirty: string
	conflict: string
	workspace: string
	bookmarks: string[]
}

function parseStatusFields(stdout: string): StatusFields {
	const fields: StatusFields = {
		change: '',
		dirty: '',
		conflict: '',
		workspace: '',
		bookmarks: [],
	}
	for (const line of stdout.split(/\r?\n/)) {
		const separator = line.indexOf('=')
		if (separator === -1) continue
		const key = line.slice(0, separator)
		const value = line.slice(separator + 1)
		// A merge @ can have several nearest bookmarked ancestors, one line each
		if (key === 'bookmarks') {
			if (value) fields.bookmarks.push(value)
		} else if (key in fields) {
			fields[key as Exclude<keyof StatusFields, 'bookmarks'>] = value
		}
	}
	return fields
}

function findJujutsuRoot(cwd: string): string | undefined {
	let current = resolve(cwd)
	while (true) {
		if (existsSync(join(current, '.jj'))) return current
		const parent = dirname(current)
		if (parent === current) return undefined
		current = parent
	}
}

export default function (pi: ExtensionAPI) {
	let repositoryRoot: string | undefined
	let operationWatcher: FSWatcher | undefined
	let refreshTimer: ReturnType<typeof setTimeout> | undefined

	const refreshStatus = async (ctx: ExtensionContext): Promise<void> => {
		if (!repositoryRoot || ctx.mode !== 'tui') return

		try {
			const result = await pi.exec(
				'jj',
				[
					'--ignore-working-copy',
					'--color=never',
					'log',
					'-r',
					STATUS_REVSET,
					'--no-graph',
					'-T',
					STATUS_TEMPLATE,
				],
				{cwd: ctx.cwd, timeout: 2000},
			)
			if (result.code !== 0) {
				ctx.ui.setStatus(STATUS_KEY, undefined)
				return
			}

			const fields = parseStatusFields(result.stdout)
			if (!fields.change) {
				ctx.ui.setStatus(STATUS_KEY, undefined)
				return
			}

			let workspace = fields.workspace.replace(/@$/, '')
			if (workspace === 'default') workspace = ''
			const prefix = workspace ? `[${workspace}] ` : ''
			const suffix = fields.bookmarks.length
				? ` ${fields.bookmarks.join(',')}`
				: ''
			const conflict = fields.conflict ? ctx.ui.theme.fg('error', '✗') : ''
			const status =
				ctx.ui.theme.fg('dim', `${prefix}${fields.change}${fields.dirty}`) +
				conflict +
				ctx.ui.theme.fg('dim', suffix)
			ctx.ui.setStatus(STATUS_KEY, status)
		} catch {
			ctx.ui.setStatus(STATUS_KEY, undefined)
		}
	}

	const scheduleStatusRefresh = (ctx: ExtensionContext): void => {
		if (refreshTimer) clearTimeout(refreshTimer)
		refreshTimer = setTimeout(() => {
			refreshTimer = undefined
			void refreshStatus(ctx)
		}, STATUS_REFRESH_DEBOUNCE_MS)
	}

	pi.on('session_start', async (_event, ctx) => {
		repositoryRoot = findJujutsuRoot(ctx.cwd)
		if (!repositoryRoot || ctx.mode !== 'tui') return

		// Watching Jujutsu's operation heads avoids polling or running jj during renders.
		try {
			// In a secondary workspace `.jj/repo` is a file holding the path of
			// the main repo's store, relative to `.jj`, and that is where
			// operations land.
			let repo = join(repositoryRoot, '.jj', 'repo')
			if (!statSync(repo).isDirectory()) {
				const target = readFileSync(repo, 'utf8').trim()
				repo = resolve(join(repositoryRoot, '.jj'), target)
			}
			const operationHeads = join(repo, 'op_heads', 'heads')
			operationWatcher = watch(operationHeads, () => scheduleStatusRefresh(ctx))
			operationWatcher.on('error', () => {
				operationWatcher?.close()
				operationWatcher = undefined
			})
		} catch {
			operationWatcher = undefined
		}

		await refreshStatus(ctx)
	})

	pi.on('session_shutdown', (_event, ctx) => {
		if (refreshTimer) clearTimeout(refreshTimer)
		refreshTimer = undefined
		operationWatcher?.close()
		operationWatcher = undefined
		repositoryRoot = undefined
		ctx.ui.setStatus(STATUS_KEY, undefined)
	})

	pi.on('before_agent_start', (event) => {
		if (!repositoryRoot) return

		return {
			systemPrompt: `${event.systemPrompt}\n\n${JUJUTSU_REPO_INSTRUCTION}`,
		}
	})

	pi.on('tool_call', (event) => {
		if (!isToolCallEventType('bash', event)) return

		const command = event.input.command
		if (!BLOCKED_PATTERNS.some((pattern) => pattern.test(command))) return
		if (!repositoryRoot) return

		return {
			block: true,
			reason:
				'This is a Jujutsu repository. Use `jj` commands instead of raw git add/stage/commit/history.',
		}
	})

	pi.registerCommand('jj-refresh', {
		description: 'Refresh Jujutsu information in the footer',
		handler: async (_args, ctx) => {
			await refreshStatus(ctx)
		},
	})
}
