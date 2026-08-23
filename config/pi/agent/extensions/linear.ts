import {mkdtemp, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import type {
	ExtensionAPI,
	TruncationResult,
} from '@earendil-works/pi-coding-agent'
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	withFileMutationQueue,
} from '@earendil-works/pi-coding-agent'
import {Type} from 'typebox'

const LINEAR_API_URL = 'https://api.linear.app/graphql'
const REQUEST_TIMEOUT_MS = 30_000
const MAX_QUERY_BYTES = 64 * 1024
const MAX_VARIABLES_BYTES = 64 * 1024
const MAX_RESPONSE_BYTES = 5 * 1024 * 1024

interface GraphQLError {
	message?: string
	locations?: Array<{line?: number; column?: number}>
	path?: Array<string | number>
	extensions?: Record<string, unknown>
}

interface GraphQLResponse {
	data?: unknown
	errors?: GraphQLError[]
	extensions?: Record<string, unknown>
}

interface LinearRateLimitDetails {
	requestRemaining?: string
	requestReset?: string
	complexity?: string
	complexityRemaining?: string
	complexityReset?: string
}

interface LinearGraphQLDetails {
	hasErrors: boolean
	responseBytes: number
	rateLimit: LinearRateLimitDetails
	truncation?: TruncationResult
	fullOutputPath?: string
}

interface RequestSignal {
	signal: AbortSignal
	timedOut: () => boolean
	cleanup: () => void
}

function createRequestSignal(signal?: AbortSignal): RequestSignal {
	const controller = new AbortController()
	let didTimeOut = false

	const abortFromCaller = () => controller.abort(signal?.reason)
	if (signal?.aborted) {
		abortFromCaller()
	} else {
		signal?.addEventListener('abort', abortFromCaller, {once: true})
	}

	const timeout = setTimeout(() => {
		didTimeOut = true
		controller.abort(new Error('Linear GraphQL request timed out'))
	}, REQUEST_TIMEOUT_MS)

	return {
		signal: controller.signal,
		timedOut: () => didTimeOut,
		cleanup: () => {
			clearTimeout(timeout)
			signal?.removeEventListener('abort', abortFromCaller)
		},
	}
}

function skipString(document: string, start: number): number {
	if (document.startsWith('"""', start)) {
		let index = start + 3
		while (index < document.length) {
			if (document.startsWith('"""', index) && document[index - 1] !== '\\') {
				return index + 3
			}
			index += 1
		}
		return document.length
	}

	let index = start + 1
	while (index < document.length) {
		if (document[index] === '\\') {
			index += 2
			continue
		}
		if (document[index] === '"') return index + 1
		index += 1
	}
	return document.length
}

/** Reject write and subscription operations without adding a GraphQL parser dependency. */
export function assertReadOnlyDocument(document: string): void {
	let index = 0
	let braceDepth = 0
	let atDefinitionStart = true

	while (index < document.length) {
		const character = document[index]

		if (character === '"') {
			index = skipString(document, index)
			continue
		}

		if (character === '#') {
			const lineEnd = document.indexOf('\n', index)
			index = lineEnd === -1 ? document.length : lineEnd + 1
			continue
		}

		if (character === '{') {
			braceDepth += 1
			atDefinitionStart = false
			index += 1
			continue
		}

		if (character === '}') {
			braceDepth = Math.max(0, braceDepth - 1)
			if (braceDepth === 0) atDefinitionStart = true
			index += 1
			continue
		}

		if (/[A-Za-z_]/.test(character)) {
			const start = index
			index += 1
			while (index < document.length && /[0-9A-Za-z_]/.test(document[index])) {
				index += 1
			}

			if (braceDepth === 0 && atDefinitionStart) {
				const token = document.slice(start, index)
				if (token === 'mutation') {
					throw new Error('Linear GraphQL mutations are disabled.')
				}
				if (token === 'subscription') {
					throw new Error('Linear GraphQL subscriptions are disabled.')
				}
				atDefinitionStart = false
			}
			continue
		}

		index += 1
	}
}

async function readResponseBody(
	response: Response,
	signal: AbortSignal,
): Promise<string> {
	const contentLength = Number(response.headers.get('content-length'))
	if (Number.isFinite(contentLength) && contentLength > MAX_RESPONSE_BYTES) {
		throw new Error(
			`Linear GraphQL response exceeds ${formatSize(MAX_RESPONSE_BYTES)}. Narrow the query or paginate it.`,
		)
	}

	if (!response.body) return ''

	const reader = response.body.getReader()
	const decoder = new TextDecoder()
	let bytesRead = 0
	let body = ''

	try {
		while (true) {
			signal.throwIfAborted()
			const {done, value} = await reader.read()
			if (done) break

			bytesRead += value.byteLength
			if (bytesRead > MAX_RESPONSE_BYTES) {
				await reader.cancel()
				throw new Error(
					`Linear GraphQL response exceeds ${formatSize(MAX_RESPONSE_BYTES)}. Narrow the query or paginate it.`,
				)
			}
			body += decoder.decode(value, {stream: true})
		}
		body += decoder.decode()
		return body
	} finally {
		reader.releaseLock()
	}
}

function rateLimitDetails(headers: Headers): LinearRateLimitDetails {
	const details: LinearRateLimitDetails = {}
	const values: Array<[keyof LinearRateLimitDetails, string]> = [
		['requestRemaining', 'x-ratelimit-requests-remaining'],
		['requestReset', 'x-ratelimit-requests-reset'],
		['complexity', 'x-complexity'],
		['complexityRemaining', 'x-ratelimit-complexity-remaining'],
		['complexityReset', 'x-ratelimit-complexity-reset'],
	]

	for (const [key, header] of values) {
		const value = headers.get(header)
		if (value) details[key] = value
	}

	return details
}

async function saveTruncatedOutput(output: string) {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	})

	if (!truncation.truncated) {
		return {text: truncation.content, truncation, fullOutputPath: undefined}
	}

	const tempDir = await mkdtemp(join(tmpdir(), 'pi-linear-'))
	const tempFile = join(tempDir, 'response.json')
	await withFileMutationQueue(tempFile, async () => {
		await writeFile(tempFile, output, {encoding: 'utf8', mode: 0o600})
	})

	const omittedLines = truncation.totalLines - truncation.outputLines
	const omittedBytes = truncation.totalBytes - truncation.outputBytes
	let text = truncation.content
	text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`
	text += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`
	text += ` ${omittedLines} lines (${formatSize(omittedBytes)}) omitted.`
	text += ` Full output saved to: ${tempFile}]`

	return {text, truncation, fullOutputPath: tempFile}
}

async function executeLinearGraphQL(
	query: string,
	variables: Record<string, unknown>,
	signal?: AbortSignal,
) {
	const apiKey = process.env.LINEAR_API_KEY?.trim()
	if (!apiKey) {
		throw new Error(
			'LINEAR_API_KEY is not configured. Export a Linear API key restricted to Read permission before starting Pi.',
		)
	}

	if (Buffer.byteLength(query, 'utf8') > MAX_QUERY_BYTES) {
		throw new Error(`GraphQL query exceeds ${formatSize(MAX_QUERY_BYTES)}.`)
	}
	assertReadOnlyDocument(query)

	const variablesJson = JSON.stringify(variables)
	if (Buffer.byteLength(variablesJson, 'utf8') > MAX_VARIABLES_BYTES) {
		throw new Error(
			`GraphQL variables exceed ${formatSize(MAX_VARIABLES_BYTES)}.`,
		)
	}

	const requestSignal = createRequestSignal(signal)
	try {
		const response = await fetch(LINEAR_API_URL, {
			method: 'POST',
			headers: {
				Authorization: apiKey,
				'Content-Type': 'application/json',
				Accept: 'application/json',
			},
			body: JSON.stringify({query, variables}),
			signal: requestSignal.signal,
		})
		const body = await readResponseBody(response, requestSignal.signal)

		if (!response.ok) {
			const retryAfter = response.headers.get('retry-after')
			const retryMessage = retryAfter ? ` Retry after ${retryAfter}.` : ''
			throw new Error(
				`Linear GraphQL returned HTTP ${response.status}.${retryMessage} ${body.slice(0, 1000)}`.trim(),
			)
		}

		let parsed: unknown
		try {
			parsed = JSON.parse(body) as unknown
		} catch {
			throw new Error('Linear GraphQL returned invalid JSON.')
		}
		if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
			throw new Error('Linear GraphQL returned an unexpected response shape.')
		}
		const result = parsed as GraphQLResponse

		const output = JSON.stringify(result, null, 2)
		const truncated = await saveTruncatedOutput(output)
		const details: LinearGraphQLDetails = {
			hasErrors: Array.isArray(result.errors) && result.errors.length > 0,
			responseBytes: Buffer.byteLength(body, 'utf8'),
			rateLimit: rateLimitDetails(response.headers),
		}

		if (truncated.truncation.truncated) {
			details.truncation = truncated.truncation
			details.fullOutputPath = truncated.fullOutputPath
		}

		return {
			content: [{type: 'text' as const, text: truncated.text}],
			details,
		}
	} catch (error) {
		if (signal?.aborted) throw new Error('Linear GraphQL request cancelled.')
		if (requestSignal.timedOut()) {
			throw new Error(
				`Linear GraphQL request timed out after ${REQUEST_TIMEOUT_MS / 1000} seconds.`,
			)
		}
		throw error
	} finally {
		requestSignal.cleanup()
	}
}

export default function linearExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: 'linear_graphql',
		label: 'Linear GraphQL',
		description: `Execute a model-generated, read-only GraphQL query against Linear. Supports schema introspection with __schema and __type; use targeted introspection such as __type(name: "Query") instead of fetching the entire schema. Mutations and subscriptions are rejected. Pass dynamic values through variables, request only needed fields, use explicit cursor pagination (normally first: 50 or less), and include pageInfo when more results may be needed. GraphQL validation errors are returned so the query can be corrected and retried. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)} (whichever is hit first), with complete truncated output saved to a private temp file. Requires LINEAR_API_KEY, which should have Linear's Read permission only.`,
		promptSnippet:
			"Query Linear's GraphQL API dynamically, including schema introspection",
		promptGuidelines: [
			'Use linear_graphql when the user asks to inspect or retrieve Linear data.',
			'When the Linear schema is uncertain, use linear_graphql with a targeted __type or __schema introspection query before constructing the data query; avoid retrieving the entire schema.',
			'Use variables and explicit cursor pagination in linear_graphql queries, request only needed fields, and inspect pageInfo before fetching another page.',
		],
		parameters: Type.Object(
			{
				query: Type.String({
					description: 'Read-only GraphQL query or introspection document',
					minLength: 1,
					maxLength: MAX_QUERY_BYTES,
				}),
				variables: Type.Optional(
					Type.Object(
						{},
						{
							description:
								'JSON object containing values for GraphQL variables',
							additionalProperties: true,
						},
					),
				),
			},
			{additionalProperties: false},
		),

		async execute(_toolCallId, params, signal) {
			try {
				return await executeLinearGraphQL(
					params.query,
					(params.variables ?? {}) as Record<string, unknown>,
					signal,
				)
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error)
				throw new Error(`Linear GraphQL failed: ${message}`)
			}
		},
	})
}
