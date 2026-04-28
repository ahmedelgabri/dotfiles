import {mkdtemp, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import type {
	ExtensionAPI,
	TruncationResult,
} from '@mariozechner/pi-coding-agent'
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	withFileMutationQueue,
} from '@mariozechner/pi-coding-agent'
import {Type} from 'typebox'

const EXA_MCP_URL = 'https://mcp.exa.ai/mcp'
const DEFAULT_RESULT_LIMIT = 5
const MAX_RESULT_LIMIT = 10

interface ExaMcpRpcResponse {
	result?: {
		content?: Array<{type?: string; text?: string}>
		isError?: boolean
	}
	error?: {code?: number; message?: string}
}

interface ExaParsedResult {
	title: string
	url: string
	content: string
}

interface WebSearchDetails {
	provider: 'exa-mcp'
	query: string
	resultCount: number
	truncation?: TruncationResult
	fullOutputPath?: string
}

function clampResultLimit(limit: number | undefined): number {
	if (typeof limit !== 'number' || !Number.isFinite(limit)) {
		return DEFAULT_RESULT_LIMIT
	}

	return Math.max(1, Math.min(MAX_RESULT_LIMIT, Math.trunc(limit)))
}

async function callExaMcp(
	query: string,
	numResults: number,
	signal?: AbortSignal,
): Promise<string> {
	const response = await fetch(EXA_MCP_URL, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			Accept: 'application/json, text/event-stream',
		},
		body: JSON.stringify({
			jsonrpc: '2.0',
			id: 1,
			method: 'tools/call',
			params: {
				name: 'web_search_exa',
				arguments: {
					query,
					numResults,
					livecrawl: 'fallback',
					type: 'auto',
					contextMaxCharacters: 3000,
				},
			},
		}),
		signal,
	})

	if (!response.ok) {
		const text = await response.text().catch(() => '')
		throw new Error(`Exa MCP error (${response.status}): ${text.slice(0, 300)}`)
	}

	const body = await response.text()

	let parsed: ExaMcpRpcResponse | null = null

	const dataLines = body.split('\n').filter((line) => line.startsWith('data:'))
	for (const line of dataLines) {
		const payload = line.slice(5).trim()
		if (!payload) {
			continue
		}

		try {
			const candidate = JSON.parse(payload) as ExaMcpRpcResponse
			if (candidate.result || candidate.error) {
				parsed = candidate
				break
			}
		} catch {
			// Ignore malformed SSE frames and keep scanning.
		}
	}

	if (!parsed) {
		try {
			const candidate = JSON.parse(body) as ExaMcpRpcResponse
			if (candidate.result || candidate.error) {
				parsed = candidate
			}
		} catch {
			// Ignore and report a clearer error below.
		}
	}

	if (!parsed) {
		throw new Error('Exa MCP returned an empty response')
	}

	if (parsed.error) {
		const code =
			typeof parsed.error.code === 'number' ? ` ${parsed.error.code}` : ''
		throw new Error(
			`Exa MCP error${code}: ${parsed.error.message || 'Unknown error'}`,
		)
	}

	if (parsed.result?.isError) {
		const message = parsed.result.content
			?.find((content) => content.type === 'text' && content.text?.trim())
			?.text?.trim()
		throw new Error(message || 'Exa MCP returned an error')
	}

	const text = parsed.result?.content?.find(
		(content) =>
			content.type === 'text' &&
			typeof content.text === 'string' &&
			content.text.trim().length > 0,
	)?.text

	if (!text) {
		throw new Error('Exa MCP returned empty content')
	}

	return text
}

function parseExaResults(text: string): ExaParsedResult[] {
	const blocks = text
		.split(/(?=^Title: )/m)
		.filter((block) => block.trim().length > 0)

	return blocks
		.map((block) => {
			const title = block.match(/^Title: (.+)/m)?.[1]?.trim() ?? ''
			const url = block.match(/^URL: (.+)/m)?.[1]?.trim() ?? ''

			let content = ''
			const textStart = block.indexOf('\nText: ')
			if (textStart >= 0) {
				content = block.slice(textStart + 7).trim()
			} else {
				const highlightsMatch = block.match(/\nHighlights:\s*\n/)
				if (highlightsMatch?.index != null) {
					content = block
						.slice(highlightsMatch.index + highlightsMatch[0].length)
						.trim()
				}
			}

			content = content.replace(/\n---\s*$/, '').trim()
			return {title, url, content}
		})
		.filter((result) => result.url.length > 0)
}

function formatExaResults(results: ExaParsedResult[]): string {
	return results
		.map((result) => {
			let entry = `## ${result.title || '(no title)'}\n${result.url}`
			if (result.content) {
				entry += `\n${result.content}`
			}
			return entry
		})
		.join('\n\n')
}

async function truncateSearchResults(output: string) {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	})

	if (!truncation.truncated) {
		return {
			text: truncation.content,
			truncation,
			fullOutputPath: undefined,
		}
	}

	const tempDir = await mkdtemp(join(tmpdir(), 'pi-web-search-'))
	const tempFile = join(tempDir, 'results.txt')
	await withFileMutationQueue(tempFile, async () => {
		await writeFile(tempFile, output, 'utf8')
	})

	const omittedLines = truncation.totalLines - truncation.outputLines
	const omittedBytes = truncation.totalBytes - truncation.outputBytes

	let text = truncation.content
	text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`
	text += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`
	text += ` ${omittedLines} lines (${formatSize(omittedBytes)}) omitted.`
	text += ` Full output saved to: ${tempFile}]`

	return {
		text,
		truncation,
		fullOutputPath: tempFile,
	}
}

async function searchExa(
	query: string,
	limit: number | undefined,
	signal?: AbortSignal,
) {
	const numResults = clampResultLimit(limit)
	const text = await callExaMcp(query, numResults, signal)
	const results = parseExaResults(text)
	const formatted =
		results.length > 0 ? formatExaResults(results) : 'No results found.'
	const truncated = await truncateSearchResults(formatted)

	const details: WebSearchDetails = {
		provider: 'exa-mcp',
		query,
		resultCount: results.length,
	}

	if (truncated.truncation.truncated) {
		details.truncation = truncated.truncation
		details.fullOutputPath = truncated.fullOutputPath
	}

	return {
		content: [{type: 'text' as const, text: truncated.text}],
		details,
	}
}

export default function webSearchExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: 'web_search',
		label: 'Web Search',
		description:
			`Search the web using Exa MCP. Returns results with titles, URLs, and snippets. ` +
			`Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)} ` +
			`(whichever is hit first). If truncated, the full output is saved to a temp file.`,
		promptSnippet: 'Search the web for current information',
		promptGuidelines: [
			'Use web_search when the user asks for information that may require up-to-date web results.',
			'Prefer specific, targeted queries over broad ones.',
			'Summarize search results for the user rather than dumping raw output.',
		],
		parameters: Type.Object({
			query: Type.String({description: 'Search query'}),
			limit: Type.Optional(
				Type.Integer({
					description: `Max number of results (default: ${DEFAULT_RESULT_LIMIT}, max: ${MAX_RESULT_LIMIT})`,
					minimum: 1,
					maximum: MAX_RESULT_LIMIT,
				}),
			),
		}),

		async execute(_toolCallId, params, signal) {
			try {
				return await searchExa(params.query, params.limit, signal)
			} catch (error) {
				if (signal?.aborted) {
					throw new Error('Search cancelled.')
				}

				const message = error instanceof Error ? error.message : String(error)
				throw new Error(`Web search failed: ${message}`)
			}
		},
	})
}
