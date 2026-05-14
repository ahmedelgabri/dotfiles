/**
 * Command Guard Extension
 *
 * Checks bash commands for potential problems before execution.
 * When an issue is detected, blocks execution and returns control
 * to the user so they can decide how to proceed.
 *
 * from: https://github.com/felixge/dotfiles/blob/a603b50cfa50e8d3c9966bcddf84e2a55d1a6b11/pi/.pi/agent/extensions/command-guard/index.ts
 */

import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'
import {isToolCallEventType} from '@earendil-works/pi-coding-agent'

interface Rule {
	name: string
	description: string
	test: (command: string) => boolean
}

const rules: Rule[] = [
	// --- Destructive filesystem operations ---
	{
		name: 'recursive-delete',
		description: 'Recursive file deletion (rm -rf / rm -r)',
		test: (cmd) =>
			/\brm\s+.*-[a-zA-Z]*r[a-zA-Z]*f?\b|\brm\s+.*-[a-zA-Z]*f[a-zA-Z]*r?\b/.test(
				cmd,
			),
	},
	{
		name: 'root-path-write',
		description: 'Writing to system root paths (/etc, /usr, /sys, /boot, /var)',
		test: (cmd) =>
			/\b(mv|cp|rm|chmod|chown|ln|tee|dd)\b.*\s+\/(etc|usr|sys|boot|var)\//.test(
				cmd,
			),
	},
	{
		name: 'home-dotfile-delete',
		description: 'Deleting home directory dotfiles',
		test: (cmd) => /\brm\b.*~\/\./.test(cmd),
	},

	// --- Privilege escalation ---
	{
		name: 'sudo',
		description: 'Running command with sudo',
		test: (cmd) => /\bsudo\b/.test(cmd),
	},

	// --- Dangerous permissions ---
	{
		name: 'world-writable',
		description: 'Setting world-writable permissions (777/666)',
		test: (cmd) => /\bchmod\b.*\b(777|666)\b/.test(cmd),
	},

	// --- Network piping (remote code execution) ---
	{
		name: 'curl-pipe-exec',
		description: 'Piping download directly to shell (curl|bash pattern)',
		test: (cmd) =>
			/\b(curl|wget)\b.*\|\s*(bash|sh|zsh|python|node|ruby|perl)\b/.test(cmd) ||
			/\b(bash|sh|zsh)\b.*<\(\s*(curl|wget)\b/.test(cmd),
	},

	// --- Git destructive operations ---
	{
		name: 'git-force-push',
		description: 'Force pushing to remote',
		test: (cmd) =>
			/\bgit\s+push\b.*--force\b|\bgit\s+push\b.*\s+-f\b/.test(cmd),
	},
	{
		name: 'git-hard-reset',
		description: 'Hard resetting git history',
		test: (cmd) => /\bgit\s+reset\b.*--hard\b/.test(cmd),
	},
	{
		name: 'git-clean-force',
		description: 'Force cleaning untracked files',
		test: (cmd) => /\bgit\s+clean\b.*-[a-zA-Z]*f/.test(cmd),
	},

	// --- Process management ---
	{
		name: 'kill-signal',
		description: 'Sending kill signals (kill -9, killall)',
		test: (cmd) => /\bkill\s+-9\b|\bkillall\b/.test(cmd),
	},

	// --- Disk operations ---
	{
		name: 'dd-command',
		description: 'Raw disk write with dd',
		test: (cmd) => /\bdd\b.*\bof=/.test(cmd),
	},
	{
		name: 'mkfs',
		description: 'Formatting filesystem',
		test: (cmd) => /\bmkfs\b/.test(cmd),
	},

	// --- Package management (global/system) ---
	{
		name: 'global-npm-install',
		description: 'Global npm install/uninstall',
		test: (cmd) =>
			/\bnpm\s+(install|i|uninstall|remove)\b.*\s+-g\b|\bnpm\s+(install|i|uninstall|remove)\b.*--global\b/.test(
				cmd,
			),
	},
	{
		name: 'brew-uninstall',
		description: 'Homebrew uninstall/remove',
		test: (cmd) => /\bbrew\s+(uninstall|remove)\b/.test(cmd),
	},

	// --- Environment variable exposure ---
	{
		name: 'env-dump',
		description: 'Dumping all environment variables (may contain secrets)',
		test: (cmd) =>
			/\benv\b(?!\s+-)|\bprintenv\b(?!\s+\w)|\bset\b\s*$/.test(cmd),
	},

	// --- Docker destructive ---
	{
		name: 'docker-system-prune',
		description: 'Docker system-wide prune',
		test: (cmd) => /\bdocker\s+system\s+prune\b/.test(cmd),
	},

	// --- SSH/network tunneling ---
	{
		name: 'reverse-shell',
		description: 'Possible reverse shell pattern',
		test: (cmd) =>
			/\b(nc|ncat|netcat)\b.*-[a-zA-Z]*e\b/.test(cmd) ||
			/\/dev\/(tcp|udp)\//.test(cmd) ||
			/\bmkfifo\b.*\b(nc|ncat)\b/.test(cmd),
	},
]

export default function (pi: ExtensionAPI) {
	pi.on('tool_call', async (event, ctx) => {
		if (!isToolCallEventType('bash', event)) return

		const command = event.input.command
		const violations = rules.filter((rule) => rule.test(command))

		if (violations.length === 0) return

		const issueList = violations.map((v) => `• ${v.description}`).join('\n')

		if (!ctx.hasUI) {
			return {
				block: true,
				reason: `Command blocked (no UI for confirmation):\n${issueList}`,
			}
		}

		const choice = await ctx.ui.select(
			`⚠️  Potential issue${violations.length > 1 ? 's' : ''} detected:\n\n` +
				`${issueList}\n\n` +
				`Command:\n  ${command}\n`,
			['Allow — run the command', 'Block — stop and let me decide'],
		)

		if (choice !== 'Allow — run the command') {
			// Abort the agent turn so control returns to the user instead of
			// letting the agent see the block reason as a tool result and continue.
			ctx.abort()
			return {
				block: true,
				reason: `Command blocked by user. Issues: ${violations.map((v) => v.name).join(', ')}`,
			}
		}
	})
}
