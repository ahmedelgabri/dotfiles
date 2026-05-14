/**
 * from: https://github.com/felixge/dotfiles/blob/a603b50cfa50e8d3c9966bcddf84e2a55d1a6b11/pi/.pi/agent/extensions/edit-answer.ts
 * Solves the same problem as answers.ts but this open the questions in your editor to edit it, answer.ts depends on LLMs extracting the questions.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from '@earendil-works/pi-coding-agent'
import {mkdirSync, readFileSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {spawnSync} from 'node:child_process'

function latestAssistantMarkdown(ctx: ExtensionContext): string | undefined {
	const branch = ctx.sessionManager.getBranch()

	for (const entry of [...branch].reverse()) {
		if (entry.type !== 'message') continue

		const message = (entry as any).message
		if (message?.role !== 'assistant' || !Array.isArray(message.content))
			continue

		const text = message.content
			.filter((block: any) => block?.type === 'text' && block.text)
			.map((block: any) => block.text)
			.join('\n\n')
			.trim()

		if (text) return text
	}
}

async function editAnswer(
	ctx: ExtensionContext & {waitForIdle?: () => Promise<void>},
) {
	await ctx.waitForIdle?.()

	const markdown = latestAssistantMarkdown(ctx)
	if (!markdown) {
		ctx.ui.notify('No assistant answer found.', 'warning')
		return
	}

	const dir = join(tmpdir(), 'pi-edit-answer')
	mkdirSync(dir, {recursive: true})
	const file = join(dir, `answer-${Date.now()}.md`)
	writeFileSync(file, markdown + '\n', 'utf8')

	ctx.ui.notify(`Opening ${file}`, 'info')
	spawnSync(process.env.EDITOR || 'vim', [file], {stdio: 'inherit'})

	const edited = readFileSync(file, 'utf8')
	ctx.ui.setEditorText(edited)
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand('edit-answer', {
		description: 'Open the latest assistant answer in $EDITOR as markdown',
		handler: async (_args, ctx) => editAnswer(ctx),
	})

	pi.registerShortcut('ctrl+shift+v', {
		description: 'Open latest assistant answer in $EDITOR',
		handler: async (ctx) => editAnswer(ctx),
	})
}
