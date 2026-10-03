/**
 * /handoff <goal>
 *
 * Compaction quietly drops detail from long sessions. A handoff instead asks
 * the model for a self-contained prompt for the next task, saves it, and
 * opens a new session with that prompt as an editable draft, linked back to
 * the previous transcripts.
 *
 * Adapted from https://github.com/megalithic/dotfiles/blob/a64a8173b4d6f5edb3ee17e7efb8a56e905dd8e2/config/pi-coding-agent/agent/extensions/handoff.ts
 */

import {mkdirSync, writeFileSync} from 'node:fs'
import {join} from 'node:path'
import type {UserMessage} from '@earendil-works/pi-ai'
import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'
import {
	BorderedLoader,
	convertToLlm,
	serializeConversation,
} from '@earendil-works/pi-coding-agent'
import {formatHandoff, handoffDirectory, sessionChain} from './session.ts'

const SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained - the new thread should be able to proceed without the old conversation

Format your response as a prompt the user can send to start the new thread. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" - just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`

interface GenerationResult {
	text: string | null
	error?: string
}

async function generate(
	ctx: ExtensionCommandContext,
	conversationText: string,
	goal: string,
	signal?: AbortSignal,
): Promise<GenerationResult> {
	const userMessage: UserMessage = {
		role: 'user',
		content: [
			{
				type: 'text',
				text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
			},
		],
		timestamp: Date.now(),
	}

	const response = await ctx.modelRegistry.complete(
		ctx.model!,
		{systemPrompt: SYSTEM_PROMPT, messages: [userMessage]},
		{signal},
	)

	if (response.stopReason === 'aborted') return {text: null}
	if (response.stopReason === 'error') {
		return {text: null, error: response.errorMessage || 'Unknown error'}
	}

	const text = response.content
		.filter((c): c is {type: 'text'; text: string} => c.type === 'text')
		.map((c) => c.text)
		.join('\n')
	if (!text) {
		return {
			text: null,
			error: `No text in response. Stop reason: ${response.stopReason}`,
		}
	}
	return {text}
}

async function generateWithLoader(
	ctx: ExtensionCommandContext,
	conversationText: string,
	goal: string,
): Promise<GenerationResult> {
	const errorResult = (err: unknown): GenerationResult => ({
		text: null,
		error: err instanceof Error ? err.message : String(err),
	})

	// custom() needs a real terminal; RPC clients get the same request
	// without the loader.
	if (ctx.mode !== 'tui') {
		return generate(ctx, conversationText, goal).catch(errorResult)
	}

	return ctx.ui.custom<GenerationResult>((tui, theme, _kb, done) => {
		const loader = new BorderedLoader(
			tui,
			theme,
			`Generating handoff prompt using ${ctx.model!.id}...`,
		)
		loader.onAbort = () => done({text: null})
		generate(ctx, conversationText, goal, loader.signal)
			.then(done)
			.catch((err) => done(errorResult(err)))
		return loader
	})
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand('handoff', {
		description: 'Transfer context to a new focused session',
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify('handoff requires interactive or RPC mode', 'error')
				return
			}

			if (!ctx.model) {
				ctx.ui.notify('No model selected', 'error')
				return
			}

			const goal = args.trim()
			if (!goal) {
				ctx.ui.notify('Usage: /handoff <goal for new thread>', 'error')
				return
			}

			// The compaction-aware context, not every message on the branch:
			// long sessions are the ones handed off, and their full branch can
			// exceed the model's context window.
			const messages = ctx.sessionManager
				.buildSessionProjection()
				.messages.filter((message) => message.role !== 'system')
			if (messages.length === 0) {
				ctx.ui.notify('No conversation to hand off', 'error')
				return
			}

			const conversationText = serializeConversation(convertToLlm(messages))
			const currentSessionFile = ctx.sessionManager.getSessionFile()
			const chain = sessionChain(
				currentSessionFile,
				ctx.sessionManager.getHeader()?.parentSession,
			)

			const result = await generateWithLoader(ctx, conversationText, goal)
			if (result.error) {
				ctx.ui.notify(`Handoff failed: ${result.error}`, 'error')
				return
			}
			if (result.text === null) {
				ctx.ui.notify('Cancelled', 'info')
				return
			}

			const handoff = formatHandoff(result.text, chain)
			const directory = handoffDirectory(ctx.cwd)
			const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
			const handoffFile = join(directory, `${timestamp}.md`)
			try {
				mkdirSync(directory, {recursive: true})
				writeFileSync(handoffFile, handoff, {encoding: 'utf8', flag: 'wx'})
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error)
				ctx.ui.notify(`Handoff save failed: ${message}`, 'error')
				return
			}

			// After replacement only the fresh ctx passed to withSession is
			// valid; the command's ctx is stale.
			const newSession = await ctx.newSession({
				parentSession: currentSessionFile,
				withSession: async (next) => {
					next.ui.setEditorText(handoff)
					next.ui.notify(
						`Handoff saved to ${handoffFile}. Submit when ready.`,
						'info',
					)
				},
			})

			if (newSession.cancelled) {
				ctx.ui.notify('New session cancelled', 'info')
			}
		},
	})
}
