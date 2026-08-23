import type {
	ExtensionAPI,
	TruncationResult,
} from '@earendil-works/pi-coding-agent'
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
} from '@earendil-works/pi-coding-agent'
import {homedir} from 'node:os'
import {join} from 'node:path'
import {Type} from 'typebox'
import {saveTruncatedOutput} from './lib/truncated-output.ts'

const LINEAR_API_URL = 'https://api.linear.app/graphql'
const CONFIG_HOME = process.env.XDG_CONFIG_HOME || join(homedir(), '.config')
// Avoid depending on an interactive shell's PATH or resolving a project-local executable.
const SECRET_COMMAND = join(CONFIG_HOME, 'zsh/bin/secret')
const SECRET_TIMEOUT_MS = 60_000
const REQUEST_TIMEOUT_MS = 30_000
const MAX_INPUT_BYTES = 64 * 1024
const MAX_RESPONSE_BYTES = 5 * 1024 * 1024

const RATE_LIMIT_HEADERS: Array<[keyof LinearRateLimitDetails, string]> = [
	['requestRemaining', 'x-ratelimit-requests-remaining'],
	['requestReset', 'x-ratelimit-requests-reset'],
	['complexity', 'x-complexity'],
	['complexityRemaining', 'x-ratelimit-complexity-remaining'],
	['complexityReset', 'x-ratelimit-complexity-reset'],
]

interface GraphQLResponse {
	errors?: unknown[]
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

function responseTooLarge(): Error {
	return new Error(
		`response exceeds ${formatSize(MAX_RESPONSE_BYTES)}. Narrow the query or paginate it.`,
	)
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
function assertReadOnlyDocument(document: string): void {
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
					throw new Error('mutations are disabled.')
				}
				if (token === 'subscription') {
					throw new Error('subscriptions are disabled.')
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
): Promise<{body: string; bytes: number}> {
	const contentLength = Number(response.headers.get('content-length'))
	if (Number.isFinite(contentLength) && contentLength > MAX_RESPONSE_BYTES) {
		throw responseTooLarge()
	}

	if (!response.body) return {body: '', bytes: 0}

	const reader = response.body.getReader()
	const decoder = new TextDecoder()
	let bytes = 0
	let body = ''

	try {
		while (true) {
			signal.throwIfAborted()
			const {done, value} = await reader.read()
			if (done) break

			bytes += value.byteLength
			if (bytes > MAX_RESPONSE_BYTES) {
				await reader.cancel()
				throw responseTooLarge()
			}
			body += decoder.decode(value, {stream: true})
		}
		body += decoder.decode()
		return {body, bytes}
	} finally {
		reader.releaseLock()
	}
}

function rateLimitDetails(headers: Headers): LinearRateLimitDetails {
	const details: LinearRateLimitDetails = {}
	for (const [key, header] of RATE_LIMIT_HEADERS) {
		const value = headers.get(header)
		if (value) details[key] = value
	}
	return details
}

async function getLinearApiKey(
	pi: ExtensionAPI,
	signal?: AbortSignal,
): Promise<string> {
	const result = await pi.exec(SECRET_COMMAND, ['get', 'linear-api-token'], {
		signal,
		timeout: SECRET_TIMEOUT_MS,
	})
	if (result.killed) {
		throw new Error(
			`keychain access timed out after ${SECRET_TIMEOUT_MS / 1000} seconds. Respond to any macOS Keychain access dialog and retry.`,
		)
	}
	if (result.code !== 0) {
		const reason = result.stderr.trim()
		throw new Error(
			reason ||
				'could not read linear-api-token from the macOS login keychain.',
		)
	}

	const apiKey = result.stdout.trim()
	if (!apiKey) {
		throw new Error('linear-api-token is empty in the macOS login keychain.')
	}
	return apiKey
}

async function executeLinearGraphQL(
	pi: ExtensionAPI,
	query: string,
	variables: Record<string, unknown>,
	signal?: AbortSignal,
) {
	if (Buffer.byteLength(query, 'utf8') > MAX_INPUT_BYTES) {
		throw new Error(`query exceeds ${formatSize(MAX_INPUT_BYTES)}.`)
	}
	assertReadOnlyDocument(query)

	if (Buffer.byteLength(JSON.stringify(variables), 'utf8') > MAX_INPUT_BYTES) {
		throw new Error(`variables exceed ${formatSize(MAX_INPUT_BYTES)}.`)
	}

	const apiKey = await getLinearApiKey(pi, signal)
	const requestSignal = AbortSignal.any(
		[signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)].filter(
			(candidate): candidate is AbortSignal => candidate !== undefined,
		),
	)

	try {
		const response = await fetch(LINEAR_API_URL, {
			method: 'POST',
			headers: {
				Authorization: apiKey,
				'Content-Type': 'application/json',
				Accept: 'application/json',
			},
			body: JSON.stringify({query, variables}),
			signal: requestSignal,
		})
		const {body, bytes} = await readResponseBody(response, requestSignal)

		if (!response.ok) {
			const retryAfter = response.headers.get('retry-after')
			const retryMessage = retryAfter ? ` Retry after ${retryAfter}.` : ''
			throw new Error(
				`returned HTTP ${response.status}.${retryMessage} ${body.slice(0, 1000)}`.trim(),
			)
		}

		let parsed: unknown
		try {
			parsed = JSON.parse(body) as unknown
		} catch {
			throw new Error('returned invalid JSON.')
		}
		if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
			throw new Error('returned an unexpected response shape.')
		}
		const result = parsed as GraphQLResponse

		const {text, ...truncated} = await saveTruncatedOutput(
			JSON.stringify(result, null, 2),
			'pi-linear-',
			'response.json',
		)
		const details: LinearGraphQLDetails = {
			hasErrors: Array.isArray(result.errors) && result.errors.length > 0,
			responseBytes: bytes,
			rateLimit: rateLimitDetails(response.headers),
			...truncated,
		}

		return {
			content: [{type: 'text' as const, text}],
			details,
		}
	} catch (error) {
		if (
			!signal?.aborted &&
			error instanceof DOMException &&
			error.name === 'TimeoutError'
		) {
			throw new Error(
				`request timed out after ${REQUEST_TIMEOUT_MS / 1000} seconds.`,
			)
		}
		throw error
	}
}

export default function linearExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: 'linear_graphql',
		label: 'Linear GraphQL',
		description: `Execute a model-generated, read-only GraphQL query against Linear. Supports schema introspection with __schema and __type; use targeted introspection such as __type(name: "Query") instead of fetching the entire schema. Mutations and subscriptions are rejected. Pass dynamic values through variables, request only needed fields, use explicit cursor pagination (normally first: 50 or less), and include pageInfo when more results may be needed. GraphQL validation errors are returned so the query can be corrected and retried. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)} (whichever is hit first), with complete truncated output saved to a private temp file. Reads linear-api-token from the macOS login keychain; the key should have Linear's Read permission only.`,
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
					pi,
					params.query,
					(params.variables ?? {}) as Record<string, unknown>,
					signal,
				)
			} catch (error) {
				if (signal?.aborted) {
					throw new Error('Linear GraphQL request cancelled.')
				}

				const message = error instanceof Error ? error.message : String(error)
				throw new Error(`Linear GraphQL failed: ${message}`)
			}
		},
	})
}
