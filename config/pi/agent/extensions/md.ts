import type {TextContent} from '@earendil-works/pi-ai'
import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'
import {constants as fsConstants} from 'node:fs'
import {access, mkdir, rename, stat, unlink, writeFile} from 'node:fs/promises'
import {homedir} from 'node:os'
import {basename, dirname, extname, isAbsolute, join, resolve} from 'node:path'

const DEFAULT_PREFIX = 'agent-message'

function timestampForFilename(timestamp = Date.now()): string {
	return new Date(timestamp)
		.toISOString()
		.replace(/[:.]/g, '-')
		.replace(/Z$/, '')
}

function expandHome(input: string): string {
	if (input === '~') return homedir()
	if (input.startsWith('~/')) return join(homedir(), input.slice(2))
	return input
}

function ensureMarkdownExtension(path: string): string {
	return extname(path).toLowerCase() === '.md' ? path : `${path}.md`
}

function normalizePathArgument(argument: string): string {
	const trimmed = argument.trim()
	if (trimmed.length >= 2) {
		const quote = trimmed[0]
		if ((quote === '"' || quote === "'") && trimmed.at(-1) === quote) {
			return trimmed.slice(1, -1)
		}
	}
	return trimmed
}

async function exists(path: string): Promise<boolean> {
	try {
		await access(path, fsConstants.F_OK)
		return true
	} catch {
		return false
	}
}

function latestAssistantMarkdown(ctx: ExtensionCommandContext): {
	markdown: string
	stopReason: string
	timestamp: number
} | null {
	const branch = ctx.sessionManager.getBranch()
	for (let index = branch.length - 1; index >= 0; index -= 1) {
		const entry = branch[index]
		if (entry.type !== 'message' || entry.message.role !== 'assistant') {
			continue
		}
		const text = entry.message.content
			.filter((block): block is TextContent => block.type === 'text')
			.map((block) => block.text)
			.join('\n\n')
			.trim()
		if (text) {
			return {
				markdown: `${text}\n`,
				stopReason: entry.message.stopReason,
				timestamp: entry.message.timestamp,
			}
		}
	}
	return null
}

async function destinationPath(
	argument: string,
	cwd: string,
	messageTimestamp: number,
): Promise<string> {
	const defaultName = `${DEFAULT_PREFIX}-${timestampForFilename(messageTimestamp)}.md`
	const raw = expandHome(normalizePathArgument(argument))
	if (!raw) {
		return join(cwd, defaultName)
	}
	const candidate = isAbsolute(raw) ? resolve(raw) : resolve(cwd, raw)
	try {
		if ((await stat(candidate)).isDirectory()) {
			return join(candidate, defaultName)
		}
	} catch {
		// A missing destination is a valid new file path.
	}
	return ensureMarkdownExtension(candidate)
}

async function atomicWrite(path: string, content: string): Promise<void> {
	await mkdir(dirname(path), {recursive: true})
	const temporary = join(
		dirname(path),
		`.${basename(path)}.${process.pid}.${Date.now()}.tmp`,
	)
	try {
		await writeFile(temporary, content, {encoding: 'utf8', mode: 0o644})
		await rename(temporary, path)
	} catch (error) {
		await unlink(temporary).catch(() => undefined)
		throw error
	}
}

export default function markdownExtension(pi: ExtensionAPI): void {
	pi.registerCommand('md', {
		description: 'Save the latest assistant message as Markdown: /md [path]',
		handler: async (args, ctx) => {
			await ctx.waitForIdle()
			const latest = latestAssistantMarkdown(ctx)
			if (!latest) {
				ctx.ui.notify('No assistant message with text was found.', 'warning')
				return
			}

			try {
				const destination = await destinationPath(
					args,
					ctx.cwd,
					latest.timestamp,
				)
				if (await exists(destination)) {
					if (!ctx.hasUI) {
						throw new Error(
							`Refusing to overwrite existing file: ${destination}`,
						)
					}
					const overwrite = await ctx.ui.confirm(
						'Overwrite Markdown file?',
						destination,
					)
					if (!overwrite) {
						ctx.ui.notify('Save cancelled.', 'info')
						return
					}
				}
				await atomicWrite(destination, latest.markdown)
				const incomplete =
					latest.stopReason === 'stop' ? '' : ` (${latest.stopReason})`
				ctx.ui.notify(`Saved${incomplete}: ${destination}`, 'info')
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error)
				ctx.ui.notify(`Could not save Markdown: ${message}`, 'error')
			}
		},
	})
}
