import assert from 'node:assert/strict'
import {mkdir, mkdtemp, realpath, rm, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import {executable, PiRpc, ScriptedModel} from '../lib/test-support.ts'

const EXTENSION = fileURLToPath(new URL('./index.ts', import.meta.url))

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

// Runs actual pi against a scripted model, with the actual rex on PATH, and
// returns the system prompt of the first request. The environment is built
// from scratch, so the Rex variables of the pane running the tests never
// leak in; `rex` prints its context from them without a server.
async function systemPrompt(rexEnv: NodeJS.ProcessEnv): Promise<string> {
	await executable('rex')
	const model = await ScriptedModel.start([{text: 'ok'}])
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-rex-')))
	try {
		const agent = join(root, 'agent')
		const tmp = join(root, 'tmp')
		await mkdir(agent)
		await mkdir(tmp)
		await writeFile(join(agent, 'models.json'), model.modelsJson)
		await writeFile(
			join(agent, 'settings.json'),
			JSON.stringify({retry: {enabled: false}}),
		)
		const rpc = await PiRpc.start(BASE_ARGS, {
			cwd: root,
			env: {
				PATH: process.env.PATH ?? '',
				HOME: root,
				XDG_CONFIG_HOME: join(root, 'config'),
				PI_CODING_AGENT_DIR: agent,
				PI_OFFLINE: '1',
				PI_SKIP_VERSION_CHECK: '1',
				TMPDIR: tmp,
				...rexEnv,
			},
		})
		try {
			await rpc.send('prompt', {message: 'hello'})
			await rpc.waitFor((record) => record.type === 'agent_settled')
			assert.equal(await rpc.close(), 0)
		} finally {
			rpc.kill()
		}
		const system = model.requests[0]?.messages.find(
			(message) => message.role === 'system',
		)
		assert.ok(system, 'the request has a system message')
		return String(system.content)
	} finally {
		model.close()
		await rm(root, {recursive: true, force: true})
	}
}

test(
	'in a Rex pane the system prompt gets the Rex context',
	{timeout: 60_000},
	async () => {
		const prompt = await systemPrompt({
			REX_BLOCK: 'block:test',
		})
		assert.match(prompt, /<rex>[\s\S]*REX_BLOCK=block:test[\s\S]*<\/rex>/)
		// Session naming is off, as in the Claude and Codex hooks.
		assert.doesNotMatch(prompt, /rex session rename/)
	},
)

test(
	'outside Rex the system prompt has no Rex section',
	{timeout: 60_000},
	async () => {
		assert.doesNotMatch(await systemPrompt({}), /<rex>/)
	},
)
