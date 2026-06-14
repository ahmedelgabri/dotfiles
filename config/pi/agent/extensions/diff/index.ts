import {randomBytes} from 'node:crypto'
import {
	createServer,
	type IncomingMessage,
	type ServerResponse,
} from 'node:http'
import type {Server} from 'node:http'
import type {AddressInfo} from 'node:net'
import {StringEnum} from '@earendil-works/pi-ai'
import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'
import {Type} from 'typebox'
import {
	loadPersistedAnnotations,
	savePersistedAnnotations,
	type StoredAnnotationAuthor,
	type StoredReviewAnnotation,
	type StoredReviewReply,
} from './annotations-store.js'
import {renderHtml} from './html.js'
import {loadUiPrefs, saveUiPrefs, type UiPrefs} from './prefs.js'
import {
	createDiffSnapshotLoader,
	execOrNull,
	loadConflictFiles,
	saveConflictFile,
	type DiffSnapshot,
} from './vcs.js'

type AnnotationAuthor = StoredAnnotationAuthor
interface ReviewReply extends StoredReviewReply {}
interface ReviewAnnotation extends StoredReviewAnnotation {}

interface ReviewSession {
	token: string
	server: Server
	snapshot: DiffSnapshot
	refresh: () => Promise<DiffSnapshot>
	annotations: ReviewAnnotation[]
	eventClients: Set<ServerResponse>
	heartbeat: NodeJS.Timeout
	finished: boolean
	uiPrefs: UiPrefs
	pi: ExtensionAPI
	ctx: ExtensionCommandContext
}

const MAX_BODY_BYTES = 1024 * 1024
const HEARTBEAT_INTERVAL_MS = 25_000
const activeSessions = new Set<ReviewSession>()
let currentSession: ReviewSession | null = null

const readBody = (req: IncomingMessage): Promise<string> =>
	new Promise((resolve, reject) => {
		let body = ''
		req.setEncoding('utf8')
		req.on('data', (chunk) => {
			body += chunk
			if (Buffer.byteLength(body, 'utf8') > MAX_BODY_BYTES) {
				reject(new Error('Request body too large'))
				req.destroy()
			}
		})
		req.on('end', () => resolve(body))
		req.on('error', reject)
	})

const send = (
	res: ServerResponse,
	status: number,
	body: string,
	type = 'text/plain; charset=utf-8',
) => {
	res.writeHead(status, {'Content-Type': type, 'Cache-Control': 'no-store'})
	res.end(body)
}

const sendJson = (res: ServerResponse, status: number, value: unknown) => {
	send(res, status, JSON.stringify(value), 'application/json; charset=utf-8')
}

const closeSession = (session: ReviewSession) => {
	activeSessions.delete(session)
	clearInterval(session.heartbeat)
	for (const client of session.eventClients) {
		try {
			client.end()
		} catch {}
	}
	session.eventClients.clear()
	if (currentSession === session) currentSession = null
	session.server.close()
}

const annotationsEvent = (session: ReviewSession): string =>
	`event: annotations\ndata: ${JSON.stringify({
		annotations: session.annotations,
	})}\n\n`

const broadcastAnnotations = (session: ReviewSession) => {
	const payload = annotationsEvent(session)
	for (const client of session.eventClients) {
		try {
			client.write(payload)
		} catch {
			session.eventClients.delete(client)
		}
	}
}

const persistAnnotations = async (session: ReviewSession) => {
	try {
		await savePersistedAnnotations(session.snapshot, session.annotations)
	} catch (error) {
		const detail = error instanceof Error ? error.message : String(error)
		session.ctx.ui.notify(`Failed to save diff annotations: ${detail}`, 'error')
	}
}

const persistAndBroadcastAnnotations = async (session: ReviewSession) => {
	await persistAnnotations(session)
	broadcastAnnotations(session)
}

const coerceSide = (value: unknown): 'additions' | 'deletions' =>
	value === 'deletions' ? 'deletions' : 'additions'

const coerceAuthor = (value: unknown): AnnotationAuthor =>
	value === 'pi' ? 'pi' : 'user'

const coerceLine = (value: unknown): number => {
	const numberValue = typeof value === 'number' ? value : Number(value)
	if (!Number.isFinite(numberValue)) return 1
	return Math.max(1, Math.trunc(numberValue))
}

const annotationFromPayload = (
	value: unknown,
	defaultAuthor: AnnotationAuthor,
): ReviewAnnotation | null => {
	if (!value || typeof value !== 'object') return null
	const record = value as Record<string, unknown>
	const path = typeof record.path === 'string' ? record.path.trim() : ''
	const text = typeof record.text === 'string' ? record.text.trim() : ''
	if (!path || !text) return null
	const start = coerceLine(record.start ?? record.line ?? record.lineNumber)
	const end = Math.max(
		start,
		coerceLine(record.end ?? record.endLine ?? record.start ?? record.line),
	)
	const side = coerceSide(record.side)
	const author =
		record.author === 'pi' || record.author === 'user'
			? (record.author as AnnotationAuthor)
			: defaultAuthor
	return {
		id: 'a-' + randomBytes(6).toString('hex'),
		path,
		side,
		start,
		end,
		endSide: coerceSide(record.endSide ?? record.side),
		text: text.slice(0, 10_000),
		author,
		createdAt: new Date().toISOString(),
		replies: [],
	}
}

const formatAnnotationLocation = (annotation: ReviewAnnotation): string => {
	const range =
		annotation.start === annotation.end
			? `${annotation.start}`
			: `${annotation.start}-${annotation.end}`
	return `${annotation.path} (${annotation.side}, lines ${range})`
}

const indent = (value: string): string =>
	value
		.split('\n')
		.map((line) => `   ${line}`)
		.join('\n')

const formatReviewMessage = (
	snapshot: DiffSnapshot,
	annotations: ReviewAnnotation[],
	note: string,
): string => {
	const lines: string[] = [
		'I reviewed the current diff in the browser.',
		'Use the diff_annotate and diff_reply tools to respond live; the browser tab is still open.',
		'',
		`Repository: ${snapshot.repoRoot}`,
		`Diff source: ${snapshot.source.label}`,
		`Diff command: ${snapshot.command}`,
	]

	if (note) lines.push('', 'Review note:', indent(note))

	if (annotations.length === 0) {
		lines.push('', 'No annotations were left.')
	} else {
		lines.push('', 'Annotations:')
		annotations.forEach((annotation, index) => {
			lines.push(
				`${index + 1}. [${annotation.id}] ${formatAnnotationLocation(annotation)} (by ${annotation.author})`,
			)
			lines.push(indent(annotation.text))
			for (const reply of annotation.replies) {
				lines.push(indent(`↳ [${reply.id}] ${reply.author}: ${reply.text}`))
			}
		})
	}

	return lines.join('\n')
}

const sendReviewToPi = (session: ReviewSession, note: string) => {
	const message = formatReviewMessage(
		session.snapshot,
		session.annotations,
		note,
	)
	try {
		if (session.ctx.isIdle()) {
			session.pi.sendUserMessage(message)
		} else {
			session.pi.sendUserMessage(message, {deliverAs: 'followUp'})
		}
		session.ctx.ui.notify('Diff annotations sent to pi', 'info')
	} catch (error) {
		const detail = error instanceof Error ? error.message : String(error)
		session.ctx.ui.notify(`Failed to send diff annotations: ${detail}`, 'error')
	}
}

const parseJsonBody = async (req: IncomingMessage): Promise<any> => {
	const body = await readBody(req)
	if (!body.trim()) return {}
	return JSON.parse(body)
}

const writeSseHeaders = (res: ServerResponse) => {
	res.writeHead(200, {
		'Content-Type': 'text/event-stream',
		'Cache-Control': 'no-cache',
		Connection: 'keep-alive',
		'X-Accel-Buffering': 'no',
	})
}

const refreshSessionSnapshot = async (session: ReviewSession) => {
	const previousKey = session.snapshot.source.key
	session.snapshot = await session.refresh()
	if (session.snapshot.source.key !== previousKey) {
		session.annotations = await loadPersistedAnnotations(
			session.snapshot,
			(message) => session.ctx.ui.notify(message, 'error'),
		)
		broadcastAnnotations(session)
	}
	return session.snapshot
}

const createRequestHandler =
	(session: ReviewSession) =>
	async (req: IncomingMessage, res: ServerResponse) => {
		try {
			const url = new URL(req.url ?? '/', 'http://127.0.0.1')
			const token = url.searchParams.get('token')
			if (token !== session.token) {
				sendJson(res, 403, {error: 'Invalid token'})
				return
			}

			if (req.method === 'GET' && url.pathname === '/') {
				send(
					res,
					200,
					renderHtml(session.token, session.uiPrefs),
					'text/html; charset=utf-8',
				)
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/prefs') {
				const payload = await parseJsonBody(req)
				session.uiPrefs = await saveUiPrefs(payload)
				sendJson(res, 200, session.uiPrefs)
				return
			}

			if (req.method === 'GET' && url.pathname === '/api/diff') {
				sendJson(res, 200, await refreshSessionSnapshot(session))
				return
			}

			if (req.method === 'GET' && url.pathname === '/api/conflicts') {
				sendJson(res, 200, {
					files: await loadConflictFiles(session.pi, session.snapshot),
				})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/conflicts/write') {
				const payload = await parseJsonBody(req)
				const path = typeof payload?.path === 'string' ? payload.path : ''
				const contents =
					typeof payload?.contents === 'string' ? payload.contents : ''
				if (!path) {
					sendJson(res, 400, {error: 'Missing conflict path'})
					return
				}
				const file = await saveConflictFile(
					session.pi,
					session.snapshot,
					path,
					contents,
				)
				sendJson(res, 200, {file})
				return
			}

			if (req.method === 'GET' && url.pathname === '/api/events') {
				writeSseHeaders(res)
				res.write(': hello\n\n')
				res.write(annotationsEvent(session))
				session.eventClients.add(res)
				const cleanup = () => {
					session.eventClients.delete(res)
				}
				req.on('close', cleanup)
				req.on('error', cleanup)
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/annotations') {
				const payload = await parseJsonBody(req)
				const annotation = annotationFromPayload(payload?.annotation, 'user')
				if (!annotation) {
					sendJson(res, 400, {error: 'Invalid annotation payload'})
					return
				}
				session.annotations = [...session.annotations, annotation]
				await persistAndBroadcastAnnotations(session)
				sendJson(res, 200, {annotation})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/annotations/delete') {
				const payload = await parseJsonBody(req)
				const id = typeof payload?.id === 'string' ? payload.id : ''
				session.annotations = session.annotations.filter((a) => a.id !== id)
				await persistAndBroadcastAnnotations(session)
				sendJson(res, 200, {ok: true})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/replies') {
				const payload = await parseJsonBody(req)
				const annotationId =
					typeof payload?.annotationId === 'string' ? payload.annotationId : ''
				const target = session.annotations.find((a) => a.id === annotationId)
				if (!target) {
					sendJson(res, 404, {error: 'Annotation not found'})
					return
				}
				const text =
					typeof payload?.text === 'string' ? payload.text.trim() : ''
				if (!text) {
					sendJson(res, 400, {error: 'Empty reply'})
					return
				}
				const reply: ReviewReply = {
					id: 'r-' + randomBytes(6).toString('hex'),
					author: coerceAuthor(payload?.author),
					text: text.slice(0, 10_000),
					createdAt: new Date().toISOString(),
				}
				target.replies = [...target.replies, reply]
				await persistAndBroadcastAnnotations(session)
				sendJson(res, 200, {reply})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/replies/delete') {
				const payload = await parseJsonBody(req)
				const annotationId =
					typeof payload?.annotationId === 'string' ? payload.annotationId : ''
				const replyId =
					typeof payload?.replyId === 'string' ? payload.replyId : ''
				const target = session.annotations.find((a) => a.id === annotationId)
				if (!target) {
					sendJson(res, 404, {error: 'Annotation not found'})
					return
				}
				target.replies = target.replies.filter((r) => r.id !== replyId)
				await persistAndBroadcastAnnotations(session)
				sendJson(res, 200, {ok: true})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/submit') {
				const payload = await parseJsonBody(req)
				const note =
					typeof payload?.note === 'string'
						? payload.note.trim().slice(0, 20_000)
						: ''
				sendReviewToPi(session, note)
				sendJson(res, 200, {ok: true})
				return
			}

			if (req.method === 'POST' && url.pathname === '/api/cancel') {
				if (!session.finished) {
					session.finished = true
					setTimeout(() => closeSession(session), 250)
				}
				sendJson(res, 200, {ok: true})
				return
			}

			sendJson(res, 404, {error: 'Not found'})
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error)
			sendJson(res, 500, {error: message})
		}
	}

const listen = (server: Server): Promise<number> =>
	new Promise((resolve, reject) => {
		server.on('error', reject)
		server.listen(0, '127.0.0.1', () => {
			const address = server.address() as AddressInfo
			resolve(address.port)
		})
	})

const openBrowser = async (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	url: string,
) => {
	const command = process.platform === 'darwin' ? 'open' : 'xdg-open'
	const result = await execOrNull(pi, command, [url], ctx.cwd)
	if (!result || result.code !== 0) {
		ctx.ui.notify(`Diff review ready: ${url}`, 'info')
		return
	}
	ctx.ui.notify('Opened browser diff review', 'info')
}

const startDiffReview = async (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	args: string,
) => {
	const refresh = createDiffSnapshotLoader(pi, ctx, args)
	const snapshot = await refresh()
	const conflicts = await loadConflictFiles(pi, snapshot)
	if (!snapshot.patch.trim() && conflicts.length === 0) {
		ctx.ui.notify('No diff or merge conflicts to review', 'info')
		return
	}
	if (conflicts.length > 0) {
		ctx.ui.notify(`Loaded ${conflicts.length} merge conflict(s)`, 'info')
	}

	const annotations = await loadPersistedAnnotations(snapshot, (message) =>
		ctx.ui.notify(message, 'error'),
	)
	if (annotations.length > 0) {
		ctx.ui.notify(
			`Loaded ${annotations.length} persisted annotation(s)`,
			'info',
		)
	}

	const uiPrefs = await loadUiPrefs()
	const token = randomBytes(24).toString('hex')
	let session: ReviewSession
	const server = createServer((req, res) => {
		void createRequestHandler(session)(req, res)
	})
	const heartbeat = setInterval(() => {
		for (const client of session.eventClients) {
			try {
				client.write(': ping\n\n')
			} catch {
				session.eventClients.delete(client)
			}
		}
	}, HEARTBEAT_INTERVAL_MS)
	session = {
		token,
		server,
		snapshot,
		refresh,
		annotations,
		eventClients: new Set(),
		heartbeat,
		finished: false,
		uiPrefs,
		pi,
		ctx,
	}

	const port = await listen(server)
	activeSessions.add(session)
	currentSession = session
	const url = `http://127.0.0.1:${port}/?token=${token}`
	ctx.ui.notify(`Diff review server listening on ${url}`, 'info')
	await openBrowser(pi, ctx, url)
}

const requireSession = (): ReviewSession => {
	if (!currentSession) {
		throw new Error(
			'No active /diff review session. Ask the user to run /diff first.',
		)
	}
	return currentSession
}

const registerTools = (pi: ExtensionAPI) => {
	pi.registerTool({
		name: 'diff_annotate',
		label: 'Diff Annotate',
		description:
			'Add a line annotation to the active /diff browser review session. The user sees it live.',
		promptSnippet: 'Annotate the diff being reviewed in /diff',
		promptGuidelines: [
			'Use diff_annotate to highlight a specific change while the user has /diff open. The path/side/line must come from the diff payload returned by /diff.',
		],
		parameters: Type.Object({
			path: Type.String({
				description: 'File path as reported by /diff (e.g. "src/foo.ts").',
			}),
			side: StringEnum(['additions', 'deletions'] as const),
			line: Type.Integer({
				description: 'Line number (1-based) the annotation starts on.',
				minimum: 1,
			}),
			endLine: Type.Optional(
				Type.Integer({
					description:
						'Last line of a multi-line annotation (defaults to line).',
					minimum: 1,
				}),
			),
			text: Type.String({description: 'Annotation body in markdown.'}),
		}),
		async execute(_id, args) {
			const session = requireSession()
			const start = args.line
			const end = Math.max(start, args.endLine ?? start)
			const side = args.side as 'additions' | 'deletions'
			const annotation: ReviewAnnotation = {
				id: 'a-' + randomBytes(6).toString('hex'),
				path: args.path,
				side,
				start,
				end,
				endSide: side,
				text: args.text,
				author: 'pi',
				createdAt: new Date().toISOString(),
				replies: [],
			}
			session.annotations = [...session.annotations, annotation]
			await persistAndBroadcastAnnotations(session)
			const range = start === end ? `${start}` : `${start}-${end}`
			return {
				content: [
					{
						type: 'text',
						text: `Added annotation ${annotation.id} on ${annotation.path}:${range}.`,
					},
				],
				details: {annotationId: annotation.id},
			}
		},
	})

	pi.registerTool({
		name: 'diff_reply',
		label: 'Diff Reply',
		description:
			'Reply to an existing annotation in the active /diff review session.',
		promptSnippet: 'Reply to a /diff annotation by id',
		parameters: Type.Object({
			annotationId: Type.String({
				description: 'Annotation id to reply to (e.g. "a-abc123").',
			}),
			text: Type.String({description: 'Reply body in markdown.'}),
		}),
		async execute(_id, args) {
			const session = requireSession()
			const target = session.annotations.find((a) => a.id === args.annotationId)
			if (!target) {
				throw new Error(`Annotation ${args.annotationId} not found.`)
			}
			const reply: ReviewReply = {
				id: 'r-' + randomBytes(6).toString('hex'),
				author: 'pi',
				text: args.text,
				createdAt: new Date().toISOString(),
			}
			target.replies = [...target.replies, reply]
			await persistAndBroadcastAnnotations(session)
			return {
				content: [
					{
						type: 'text',
						text: `Replied to ${args.annotationId} as ${reply.id}.`,
					},
				],
				details: {replyId: reply.id},
			}
		},
	})

	pi.registerTool({
		name: 'diff_list_annotations',
		label: 'Diff Annotations',
		description: 'List annotations in the active /diff review session.',
		parameters: Type.Object({}),
		async execute() {
			const session = requireSession()
			return {
				content: [
					{
						type: 'text',
						text: JSON.stringify(session.annotations, null, 2),
					},
				],
				details: {
					annotations: session.annotations,
					source: session.snapshot.source,
				},
			}
		},
	})
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand('diff', {
		description:
			'Review a working diff, PR, commit, git ref, or jj revision in a browser and exchange annotations with pi',
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify('/diff requires interactive or RPC mode', 'error')
				return
			}

			try {
				await startDiffReview(pi, ctx, args)
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error)
				ctx.ui.notify(`Failed to start diff review: ${message}`, 'error')
			}
		},
	})

	registerTools(pi)

	pi.on('session_shutdown', () => {
		for (const session of activeSessions) {
			closeSession(session)
		}
		activeSessions.clear()
		currentSession = null
	})
}
