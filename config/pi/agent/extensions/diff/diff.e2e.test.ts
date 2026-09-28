import assert from 'node:assert/strict'
import {spawn, spawnSync} from 'node:child_process'
import {constants} from 'node:fs'
import {
	access,
	mkdir,
	mkdtemp,
	readFile,
	realpath,
	rm,
	symlink,
	writeFile,
} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {delimiter, dirname, join} from 'node:path'
import {createInterface} from 'node:readline'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import type {
	StoredReviewAnnotation,
	StoredReviewReply,
} from './annotations-store.ts'
import type {ConflictFile, DiffSnapshot} from './vcs.ts'

interface RpcRecord {
	type: string
	id?: string
	success?: boolean
	error?: string
	notifyType?: string
	message?: string
	data?: {commands: {name: string}[]}
}

async function executable(name: string): Promise<string> {
	for (const directory of (process.env.PATH ?? '').split(delimiter)) {
		const path = join(directory, name)
		try {
			await access(path, constants.X_OK)
			return await realpath(path)
		} catch {}
	}
	throw new Error(`${name} must be installed`)
}

async function withTimeout<T>(
	promise: Promise<T>,
	milliseconds: number,
): Promise<T> {
	let timer: ReturnType<typeof setTimeout> | undefined
	try {
		return await Promise.race([
			promise,
			new Promise<never>((_, reject) => {
				timer = setTimeout(
					() => reject(new Error('Timed out waiting for Pi')),
					milliseconds,
				)
			}),
		])
	} finally {
		clearTimeout(timer)
	}
}

async function request<T>(
	base: string,
	path: string,
	payload?: unknown,
	expected = 200,
	token = true,
): Promise<T> {
	const url = new URL(base)
	url.pathname = path
	if (!token) url.search = ''
	const response = await fetch(url, {
		method: payload === undefined ? 'GET' : 'POST',
		headers: {'Content-Type': 'application/json'},
		body: payload === undefined ? undefined : JSON.stringify(payload),
		signal: AbortSignal.timeout(10_000),
	})
	assert.equal(response.status, expected)
	return response.headers.get('content-type')?.includes('application/json')
		? ((await response.json()) as T)
		: ((await response.text()) as T)
}

async function annotationsFromEvents(
	base: string,
): Promise<StoredReviewAnnotation[]> {
	const url = new URL(base)
	url.pathname = '/api/events'
	const response = await fetch(url, {signal: AbortSignal.timeout(10_000)})
	assert.equal(response.status, 200)
	assert.ok(response.body)
	const reader = response.body.getReader()
	const decoder = new TextDecoder()
	let buffer = ''
	try {
		while (true) {
			const {done, value} = await reader.read()
			assert.equal(done, false, 'SSE stream closed before annotations arrived')
			buffer += decoder.decode(value, {stream: true})
			const boundary = buffer.indexOf('\n\n')
			if (boundary === -1) continue
			const frames = buffer.slice(0, buffer.lastIndexOf('\n\n')).split('\n\n')
			buffer = buffer.slice(buffer.lastIndexOf('\n\n') + 2)
			for (const frame of frames) {
				const data = frame.split('\n').find((line) => line.startsWith('data: '))
				if (data) return JSON.parse(data.slice(6)).annotations
			}
		}
	} finally {
		await reader.cancel()
	}
}

test(
	'actual Pi RPC, HTTP, and annotation persistence',
	{timeout: 60_000},
	async () => {
		const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-diff-e2e-')))
		try {
			const repo = join(root, 'repo')
			const tools = join(root, 'tools')
			await mkdir(repo)
			await mkdir(tools)
			// Omit browser launchers to exercise the extension's URL fallback.
			for (const name of ['jj', 'git', 'bash']) {
				await symlink(await executable(name), join(tools, name))
			}
			const env = {
				PATH: tools,
				HOME: root,
				XDG_CONFIG_HOME: root,
				JJ_CONFIG: '/dev/null',
				GIT_CONFIG_GLOBAL: '/dev/null',
				GIT_CONFIG_NOSYSTEM: '1',
				PI_CODING_AGENT_DIR: join(root, 'agent'),
				PI_OFFLINE: '1',
				PI_SKIP_VERSION_CHECK: '1',
			}
			function jj(...args: string[]) {
				const result = spawnSync(
					join(tools, 'jj'),
					[
						'--config',
						'user.name=Test',
						'--config',
						'user.email=test@example.invalid',
						'--config',
						'signing.behavior=drop',
						...args,
					],
					{cwd: repo, env, encoding: 'utf8', timeout: 15_000},
				)
				assert.equal(result.status, 0, result.stderr)
				return result.stdout.trim()
			}
			jj('git', 'init', '--colocate')
			await writeFile(join(repo, 'file.txt'), 'new file\n')
			const outside = join(root, 'outside.txt')
			await writeFile(outside, 'unchanged\n')
			const extension = dirname(fileURLToPath(import.meta.url))
			const child = spawn(
				await executable('pi'),
				[
					'--mode',
					'rpc',
					'--no-session',
					'--offline',
					'--no-extensions',
					'--no-context-files',
					'--no-skills',
					'--no-prompt-templates',
					'--no-themes',
					'--no-tools',
					'--no-approve',
					'--extension',
					extension,
				],
				{cwd: repo, env, stdio: 'pipe'},
			)
			let stderr = ''
			child.stderr.setEncoding('utf8').on('data', (data: string) => {
				stderr += data
			})
			child.on('error', (error) => {
				stderr += error.message
			})
			const exited = new Promise<number | null>((resolve) =>
				child.once('close', resolve),
			)
			const lines = createInterface({input: child.stdout})
			const records = lines[Symbol.asyncIterator]()
			let serial = 0

			async function command(type: string, payload = {}) {
				const id = String(++serial)
				child.stdin.write(JSON.stringify({id, type, ...payload}) + '\n')
				const messages: string[] = []
				while (true) {
					const {done, value} = await withTimeout(records.next(), 30_000)
					assert.equal(done, false, stderr || 'Pi exited before responding')
					const record = JSON.parse(value!) as RpcRecord
					assert.notEqual(
						record.type,
						'agent_start',
						'Test must not invoke a model',
					)
					if (record.type === 'extension_ui_request') {
						assert.notEqual(
							record.notifyType,
							'error',
							record.message ?? 'Pi extension error',
						)
						messages.push(record.message ?? '')
					}
					if (record.type === 'response' && record.id === id) {
						assert.equal(
							record.success,
							true,
							record.error ?? 'RPC command failed',
						)
						return {record, messages}
					}
				}
			}

			async function startReview() {
				const {messages} = await command('prompt', {message: '/diff --'})
				const url = messages
					.map(
						(message) =>
							message.match(
								/http:\/\/127\.0\.0\.1:\d+\/\?token=[a-f0-9]+/,
							)?.[0],
					)
					.find(Boolean)
				assert.ok(url, 'The real extension did not start its HTTP server')
				assert.ok(
					messages.some((message) => message.startsWith('Diff review ready:')),
				)
				return url
			}

			try {
				const {record} = await command('get_commands')
				assert.ok(record.data?.commands.some((item) => item.name === 'diff'))
				const url = await startReview()
				assert.deepEqual(
					await request(url, '/api/diff', undefined, 403, false),
					{error: 'Invalid token'},
				)
				const snapshot = await request<DiffSnapshot>(url, '/api/diff')
				assert.equal(snapshot.vcs, 'jj')
				assert.equal(snapshot.files[0].path, 'file.txt')
				assert.ok(snapshot.patch.includes('new file'))
				assert.ok(
					(await request<string>(url, '/')).toLowerCase().includes('<html'),
				)
				assert.deepEqual(await request(url, '/api/annotations', {}, 400), {
					error: 'Invalid annotation payload',
				})
				const {annotation} = await request<{
					annotation: StoredReviewAnnotation
				}>(url, '/api/annotations', {
					annotation: {path: 'file.txt', line: 1, text: 'Review note'},
				})
				const {reply} = await request<{reply: StoredReviewReply}>(
					url,
					'/api/replies',
					{
						annotationId: annotation.id,
						text: 'Reply',
					},
				)
				assert.equal(reply.text, 'Reply')
				await request(
					url,
					'/api/replies',
					{annotationId: 'missing', text: 'Reply'},
					404,
				)
				await request(
					url,
					'/api/conflicts/write',
					{path: '../outside.txt', contents: 'changed'},
					500,
				)
				await symlink(outside, join(repo, 'linked.txt'))
				await request(
					url,
					'/api/conflicts/write',
					{path: 'linked.txt', contents: 'changed'},
					500,
				)
				assert.equal(await readFile(outside, 'utf8'), 'unchanged\n')
				await request(url, '/api/cancel', {})
				const reopened = await startReview()
				const persisted = await annotationsFromEvents(reopened)
				assert.equal(persisted.length, 1)
				assert.equal(persisted[0].id, annotation.id)
				assert.equal(persisted[0].replies[0].id, reply.id)
				await request(reopened, '/api/annotations/delete', {id: annotation.id})
				await request(reopened, '/api/cancel', {})

				await rm(join(repo, 'linked.txt'))
				jj('describe', '-m', 'base')
				const base = jj('log', '-r', '@', '--no-graph', '-T', 'change_id')
				jj('new')
				await writeFile(join(repo, 'file.txt'), 'left\n')
				jj('describe', '-m', 'left')
				const left = jj('log', '-r', '@', '--no-graph', '-T', 'change_id')
				jj('new', base)
				await writeFile(join(repo, 'file.txt'), 'right\n')
				jj('describe', '-m', 'right')
				const right = jj('log', '-r', '@', '--no-graph', '-T', 'change_id')
				jj('new', left, right)
				assert.equal(jj('diff', '--types'), '')
				const merge = await startReview()
				const {files} = await request<{files: ConflictFile[]}>(
					merge,
					'/api/conflicts',
				)
				assert.equal(files.length, 1)
				assert.equal(files[0].path, 'file.txt')
				assert.equal(files[0].resolved, false)
				const {file} = await request<{file: ConflictFile}>(
					merge,
					'/api/conflicts/write',
					{
						path: 'file.txt',
						contents: 'resolved\n',
					},
				)
				assert.equal(file.resolved, true)
				assert.equal(
					await readFile(join(repo, 'file.txt'), 'utf8'),
					'resolved\n',
				)
				assert.deepEqual(await request(merge, '/api/conflicts'), {files: []})
				await request(merge, '/api/cancel', {})
			} finally {
				child.stdin.end()
				try {
					assert.equal(await withTimeout(exited, 15_000), 0, stderr)
				} finally {
					if (child.exitCode === null) child.kill('SIGKILL')
					await exited
					lines.close()
				}
				assert.equal(stderr, '')
			}
		} finally {
			await rm(root, {recursive: true, force: true})
		}
	},
)
