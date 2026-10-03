import {spawn, type ChildProcessWithoutNullStreams} from 'node:child_process'
import {constants} from 'node:fs'
import {access, realpath} from 'node:fs/promises'
import {createServer, type Server, type ServerResponse} from 'node:http'
import type {AddressInfo} from 'node:net'
import {delimiter, join} from 'node:path'
import {createInterface} from 'node:readline'

/** Resolve a real executable from PATH, as the extension tests run them. */
export async function executable(name: string): Promise<string> {
	for (const directory of (process.env.PATH ?? '').split(delimiter)) {
		const path = join(directory, name)
		try {
			await access(path, constants.X_OK)
			return await realpath(path)
		} catch {}
	}
	throw new Error(`${name} must be installed`)
}

export interface RpcRecord {
	type: string
	id?: string
	success?: boolean
	error?: string
	method?: string
	notifyType?: string
	message?: string
	text?: string
	data?: Record<string, unknown>
}

/**
 * Drives an actual `pi --mode rpc` process: every stdout record is kept, so
 * a test can wait for responses, events, and extension UI requests in order.
 */
export class PiRpc {
	readonly records: RpcRecord[] = []
	stderr = ''
	private serial = 0
	private waiters = new Set<() => void>()
	private readonly child: ChildProcessWithoutNullStreams
	private readonly exited: Promise<number | null>

	private constructor(child: ChildProcessWithoutNullStreams) {
		this.child = child
		child.stderr.setEncoding('utf8').on('data', (data: string) => {
			this.stderr += data
		})
		child.on('error', (error) => {
			this.stderr += error.message
		})
		createInterface({input: child.stdout}).on('line', (line) => {
			this.records.push(JSON.parse(line) as RpcRecord)
			for (const wake of this.waiters) wake()
		})
		this.exited = new Promise((resolve) => child.once('close', resolve))
	}

	static async start(
		args: string[],
		options: {cwd: string; env: NodeJS.ProcessEnv},
	): Promise<PiRpc> {
		const child = spawn(await executable('pi'), ['--mode', 'rpc', ...args], {
			...options,
			stdio: 'pipe',
		})
		return new PiRpc(child)
	}

	/** Resolve with the first record at or after `from` that matches. */
	waitFor(
		predicate: (record: RpcRecord) => boolean,
		{from = 0, timeout = 30_000} = {},
	): Promise<RpcRecord> {
		return new Promise((resolve, reject) => {
			const check = () => {
				const record = this.records.slice(from).find(predicate)
				if (!record) return
				cleanup()
				resolve(record)
			}
			const timer = setTimeout(() => {
				cleanup()
				reject(new Error(`Timed out waiting for Pi\n${this.stderr}`))
			}, timeout)
			const cleanup = () => {
				clearTimeout(timer)
				this.waiters.delete(check)
			}
			this.waiters.add(check)
			check()
		})
	}

	/** Send a command and return the records it produced up to its response. */
	async send(
		type: string,
		payload: Record<string, unknown> = {},
		timeout?: number,
	): Promise<{response: RpcRecord; records: RpcRecord[]}> {
		const id = String(++this.serial)
		const from = this.records.length
		this.child.stdin.write(JSON.stringify({id, type, ...payload}) + '\n')
		const response = await this.waitFor(
			(record) => record.type === 'response' && record.id === id,
			{from, timeout},
		)
		return {response, records: this.records.slice(from)}
	}

	async close(): Promise<number | null> {
		this.child.stdin.end()
		return this.exited
	}

	/** For `finally` blocks: a failed assertion must not leave Pi running. */
	kill(): void {
		if (this.child.exitCode === null && this.child.signalCode === null) {
			this.child.kill()
		}
	}
}

export type ScriptedReply =
	| {text: string}
	| {toolCall: {name: string; arguments: Record<string, unknown>}}
	| {status: number}

export interface ScriptedRequest {
	messages: {role: string; content: unknown}[]
	[key: string]: unknown
}

/**
 * A loopback OpenAI-compatible chat completions endpoint for offline
 * integration tests. Each request gets the next scripted reply, streamed
 * the way the real API streams it; once they run out it answers HTTP 500.
 */
export class ScriptedModel {
	readonly requests: ScriptedRequest[] = []
	private readonly replies: ScriptedReply[]
	private readonly server: Server

	private constructor(replies: ScriptedReply[]) {
		this.replies = [...replies]
		this.server = createServer((request, response) => {
			let body = ''
			request.setEncoding('utf8')
			request.on('data', (chunk: string) => (body += chunk))
			request.on('end', () => {
				this.requests.push(JSON.parse(body) as ScriptedRequest)
				this.respond(response, this.replies.shift() ?? {status: 500})
			})
		})
	}

	static async start(replies: ScriptedReply[] = []): Promise<ScriptedModel> {
		const model = new ScriptedModel(replies)
		await new Promise<void>((resolve) =>
			model.server.listen(0, '127.0.0.1', resolve),
		)
		return model
	}

	/** A models.json provider named `scripted` with one model, `test`. */
	get modelsJson(): string {
		const {port} = this.server.address() as AddressInfo
		return JSON.stringify({
			providers: {
				scripted: {
					baseUrl: `http://127.0.0.1:${port}/v1`,
					api: 'openai-completions',
					apiKey: 'dummy',
					models: [{id: 'test'}],
				},
			},
		})
	}

	close(): void {
		this.server.close()
	}

	private respond(response: ServerResponse, reply: ScriptedReply): void {
		if ('status' in reply) {
			response.writeHead(reply.status, {'content-type': 'application/json'})
			response.end(JSON.stringify({error: {message: 'scripted failure'}}))
			return
		}
		const chunk = (delta: object, finishReason: string | null) =>
			`data: ${JSON.stringify({
				id: 'chatcmpl-scripted',
				object: 'chat.completion.chunk',
				created: 0,
				model: 'test',
				choices: [{index: 0, delta, finish_reason: finishReason}],
			})}\n\n`
		response.writeHead(200, {'content-type': 'text/event-stream'})
		if ('text' in reply) {
			response.write(chunk({role: 'assistant', content: reply.text}, null))
			response.write(chunk({}, 'stop'))
		} else {
			const toolCall = {
				index: 0,
				id: `call_${this.requests.length}`,
				type: 'function',
				function: {
					name: reply.toolCall.name,
					arguments: JSON.stringify(reply.toolCall.arguments),
				},
			}
			response.write(chunk({role: 'assistant', tool_calls: [toolCall]}, null))
			response.write(chunk({}, 'tool_calls'))
		}
		response.end('data: [DONE]\n\n')
	}
}
