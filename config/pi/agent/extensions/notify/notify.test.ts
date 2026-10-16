import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {mkdir, mkdtemp, realpath, rm, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'
import {PANE_IDENTITY_VARIABLES} from '../lib/pane-identity.ts'
import {executable, PiRpc, ScriptedModel} from '../lib/test-support.ts'
import notify from './index.ts'

const EXTENSION = fileURLToPath(new URL('./index.ts', import.meta.url))

type Settled = (event: unknown, ctx: {mode: string}) => void

function settledHandler(): Settled {
	let handler: Settled | undefined
	notify({
		on: (name: string, fn: Settled) => {
			if (name === 'agent_settled') handler = fn
		},
	} as unknown as ExtensionAPI)
	assert.ok(handler)
	return handler
}

function captureStdout(
	run: () => void,
	env: Record<string, string | undefined> = {},
): string {
	const saved = Object.fromEntries(
		Object.keys(env).map((name) => [name, process.env[name]]),
	)
	const write = process.stdout.write.bind(process.stdout)
	let output = ''
	process.stdout.write = ((chunk: string) => {
		output += chunk
		return true
	}) as typeof process.stdout.write
	for (const [name, value] of Object.entries(env))
		if (value === undefined) delete process.env[name]
		else process.env[name] = value
	try {
		run()
	} finally {
		process.stdout.write = write
		for (const [name, value] of Object.entries(saved))
			if (value === undefined) delete process.env[name]
			else process.env[name] = value
	}
	return output
}

// The terminal and session the tests run in must not decide the outcome.
const PLAIN = Object.fromEntries(
	[...PANE_IDENTITY_VARIABLES, 'KITTY_WINDOW_ID'].map((name) => [
		name,
		undefined,
	]),
)

test('only the interactive TUI gets a notification', () => {
	const settled = settledHandler()
	const plain = PLAIN
	for (const mode of ['print', 'json', 'rpc'])
		assert.equal(
			captureStdout(() => settled({}, {mode}), plain),
			'',
			mode,
		)
	assert.equal(
		captureStdout(() => settled({}, {mode: 'tui'}), plain),
		'\x1b]777;notify;Pi;Ready for input\x07',
	)
})

test('the TUI notification keeps its tmux and Kitty forms', () => {
	const settled = settledHandler()
	assert.equal(
		captureStdout(() => settled({}, {mode: 'tui'}), {
			...PLAIN,
			TMUX: '/tmp/t,1,0',
		}),
		'\x1bPtmux;\x1b\x1b]777;notify;Pi;Ready for input\x07\x1b\\',
	)
	assert.equal(
		captureStdout(() => settled({}, {mode: 'tui'}), {
			...PLAIN,
			KITTY_WINDOW_ID: '1',
		}),
		'\x1b]99;i=1:d=0;Pi\x1b\\\x1b]99;i=1:p=body;Ready for input\x1b\\',
	)
})

test('a Rex session gets no notification from the extension', () => {
	const settled = settledHandler()
	assert.equal(
		captureStdout(() => settled({}, {mode: 'tui'}), {
			...PLAIN,
			REX_SESSION: 'session:1',
		}),
		'',
	)
})

async function withAgent(
	modelsJson: string,
	run: (env: NodeJS.ProcessEnv, cwd: string) => Promise<void>,
): Promise<void> {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-notify-')))
	try {
		const agent = join(root, 'agent')
		const tmp = join(root, 'tmp')
		await mkdir(agent)
		await mkdir(tmp)
		await writeFile(join(agent, 'models.json'), modelsJson)
		await writeFile(
			join(agent, 'settings.json'),
			JSON.stringify({retry: {enabled: false}}),
		)
		await run(
			{
				PATH: process.env.PATH ?? '',
				HOME: root,
				XDG_CONFIG_HOME: join(root, 'config'),
				PI_CODING_AGENT_DIR: agent,
				PI_OFFLINE: '1',
				PI_SKIP_VERSION_CHECK: '1',
				TMPDIR: tmp,
			},
			root,
		)
	} finally {
		await rm(root, {recursive: true, force: true})
	}
}

const BASE_ARGS = [
	'--no-session',
	'--no-extensions',
	'--no-context-files',
	'--no-skills',
	'--no-prompt-templates',
	'--no-themes',
	'--no-tools',
	'--no-approve',
	'--model',
	'scripted/test',
	'--extension',
	EXTENSION,
]

test(
	'actual pi in print mode prints only the answer',
	{timeout: 60_000},
	async () => {
		const model = await ScriptedModel.start([{text: 'just the answer'}])
		try {
			await withAgent(model.modelsJson, async (env, cwd) => {
				// pi -p reads piped stdin until EOF, so stdin must not be a pipe.
				const child = spawn(
					await executable('pi'),
					[...BASE_ARGS, '-p', 'hello'],
					{
						cwd,
						env,
						stdio: ['ignore', 'pipe', 'pipe'],
					},
				)
				let stdout = ''
				let stderr = ''
				child.stdout
					.setEncoding('utf8')
					.on('data', (data: string) => (stdout += data))
				child.stderr
					.setEncoding('utf8')
					.on('data', (data: string) => (stderr += data))
				const code = await new Promise((resolve) =>
					child.once('close', resolve),
				)
				assert.equal(code, 0, stderr)
				assert.equal(stderr, '')
				assert.equal(stdout.includes('\x1b'), false, JSON.stringify(stdout))
				assert.equal(stdout.trim(), 'just the answer')
			})
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi in RPC mode writes no notification escapes',
	{timeout: 60_000},
	async () => {
		const model = await ScriptedModel.start([{text: 'ok'}])
		try {
			await withAgent(model.modelsJson, async (env, cwd) => {
				// Pi moves extension stdout writes to stderr outside the TUI.
				const rpc = await PiRpc.start(BASE_ARGS, {cwd, env})
				try {
					await rpc.send('prompt', {message: 'hello'})
					await rpc.waitFor((record) => record.type === 'agent_settled')
					assert.equal(await rpc.close(), 0)
					assert.equal(rpc.stderr, '')
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)
