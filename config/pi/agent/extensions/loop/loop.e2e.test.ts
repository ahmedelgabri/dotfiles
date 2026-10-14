import assert from 'node:assert/strict'
import {execFile} from 'node:child_process'
import {randomBytes} from 'node:crypto'
import {mkdir, mkdtemp, readdir, readFile, realpath, rm} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import {PiRpc, type RpcRecord} from '../lib/test-support.ts'
import {FILES, readStateFile, type LoopStateFile} from './core.ts'
import {INBOX_CUSTOM_TYPE} from './inbox.ts'
import {withoutPaneIdentity} from '../lib/pane-identity.ts'
import {classifyProcess, readProcessTable} from './runtime.ts'

// Uses the real agent directory, credentials, and model (PI_E2E_MODEL, or
// the default). The loop state is temporary, so the suite never touches real
// loops, and the owner gets no pane identity, so pane-aware extensions leave
// the terminal running the suite alone.
const LOOP_EXTENSION = fileURLToPath(new URL('./index.ts', import.meta.url))
const MODEL = process.env.PI_E2E_MODEL
const OWNER_ARGS = [
	'--no-session',
	'--no-extensions',
	'--no-context-files',
	'--no-skills',
	'--no-prompt-templates',
	'--no-themes',
	'--no-approve',
	'--no-tools',
	...(MODEL ? ['--model', MODEL] : []),
	'--thinking',
	'off',
	'--extension',
	LOOP_EXTENSION,
]

interface Fixture {
	root: string
	state: string
	env: NodeJS.ProcessEnv
	recorded: Array<{pid: number; lstart: string}>
}

async function withFixture(
	run: (fixture: Fixture) => Promise<void>,
): Promise<void> {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-loop-e2e-')))
	const state = join(root, 'state')
	const tmp = join(root, 'tmp')
	await mkdir(state)
	await mkdir(tmp)
	const recorded: Fixture['recorded'] = []
	let passed = false
	try {
		await run({
			root,
			state,
			recorded,
			env: {
				...withoutPaneIdentity(process.env),
				PI_SKIP_VERSION_CHECK: '1',
				PI_LOOP_STATE_DIR: state,
				TMPDIR: tmp,
			},
		})
		passed = true
	} finally {
		// Only processes this test recorded, and only while their start time
		// still matches.
		const table = await readProcessTable()
		for (const {pid, lstart} of recorded)
			if (classifyProcess(table, pid, lstart) === 'alive')
				try {
					process.kill(pid, 'SIGKILL')
				} catch {}
		if (passed) await rm(root, {recursive: true, force: true})
		else console.error(`Kept the failed fixture in ${root}`)
	}
}

async function waitUntil(
	predicate: () => boolean | Promise<boolean>,
	timeout: number,
): Promise<void> {
	const deadline = Date.now() + timeout
	while (!(await predicate())) {
		if (Date.now() > deadline) throw new Error('Timed out waiting')
		await new Promise((resolve) => setTimeout(resolve, 100))
	}
}

async function loopDir(state: string): Promise<string> {
	let names: string[] = []
	await waitUntil(async () => {
		names = (await readdir(state)).filter((name) => name !== 'inboxes')
		return names.length > 0
	}, 30_000)
	return join(state, names[0])
}

async function waitForState(
	dir: string,
	predicate: (state: LoopStateFile) => boolean,
	timeout: number,
): Promise<LoopStateFile> {
	let state = await readStateFile(dir)
	await waitUntil(
		async () => predicate((state = await readStateFile(dir))),
		timeout,
	)
	return state
}

type MessageRecord = RpcRecord & {
	message?: {role?: string; customType?: string; content?: unknown}
}

function messages(rpc: PiRpc, role: string, from = 0): MessageRecord[] {
	return (rpc.records.slice(from) as MessageRecord[]).filter(
		(record) => record.type === 'message_end' && record.message?.role === role,
	)
}

function textOf(record: MessageRecord): string {
	const content = record.message?.content
	if (typeof content === 'string') return content
	return Array.isArray(content)
		? content.map((part: {text?: string}) => part.text ?? '').join('')
		: ''
}

async function stopAndClose(rpc: PiRpc): Promise<void> {
	await rpc.send('prompt', {message: '/loop stop'}, 60_000)
	assert.equal(await rpc.close(), 0, rpc.stderr)
}

test(
	'a reactive report makes the owner respond by itself',
	{timeout: 10 * 60_000},
	async () =>
		withFixture(async (fixture) => {
			const token = `TOKEN-${randomBytes(4).toString('hex')}`
			const rpc = await PiRpc.start(OWNER_ARGS, {
				cwd: fixture.root,
				env: fixture.env,
			})
			try {
				await rpc.send('prompt', {
					message: `/loop 30s Reply with exactly this text and nothing else: ${token}`,
				})
				const report = await rpc.waitFor(
					(record) =>
						(record as MessageRecord).message?.customType ===
							INBOX_CUSTOM_TYPE && JSON.stringify(record).includes(token),
					{timeout: 5 * 60_000},
				)
				const from = rpc.records.indexOf(report)
				await rpc.waitFor((record) => record.type === 'agent_settled', {
					from,
					timeout: 5 * 60_000,
				})
				assert.equal(
					messages(rpc, 'user').length,
					0,
					'nobody prompted the owner',
				)
				assert.ok(
					messages(rpc, 'assistant', from).length > 0,
					'the owner responded by itself',
				)
				await stopAndClose(rpc)
			} finally {
				rpc.kill()
			}
		}),
)

test(
	'a passive report joins the context without a turn, and the model can quote it',
	{timeout: 10 * 60_000},
	async () =>
		withFixture(async (fixture) => {
			const token = `TOKEN-${randomBytes(4).toString('hex')}`
			const rpc = await PiRpc.start(OWNER_ARGS, {
				cwd: fixture.root,
				env: fixture.env,
			})
			try {
				await rpc.send('prompt', {
					message: `/loop --passive 30s Reply with exactly this text and nothing else: ${token}`,
				})
				await rpc.waitFor(
					(record) =>
						(record as MessageRecord).message?.customType ===
							INBOX_CUSTOM_TYPE && JSON.stringify(record).includes(token),
					{timeout: 5 * 60_000},
				)
				await new Promise((resolve) => setTimeout(resolve, 3000))
				assert.equal(
					messages(rpc, 'assistant').length,
					0,
					'passive delivery started no turn',
				)
				const from = rpc.records.length
				await rpc.send(
					'prompt',
					{
						message:
							'A background loop report is in your context. Reply with the token it contains and nothing else.',
					},
					60_000,
				)
				await rpc.waitFor((record) => record.type === 'agent_settled', {
					from,
					timeout: 5 * 60_000,
				})
				const answer = messages(rpc, 'assistant', from).map(textOf).join('\n')
				assert.match(answer, new RegExp(token), answer)
				await stopAndClose(rpc)
			} finally {
				rpc.kill()
			}
		}),
)

test(
	'a /loop send message changes the next run',
	{timeout: 10 * 60_000},
	async () =>
		withFixture(async (fixture) => {
			const word = `WORD${randomBytes(3).toString('hex').toUpperCase()}`
			const rpc = await PiRpc.start(OWNER_ARGS, {
				cwd: fixture.root,
				env: fixture.env,
			})
			try {
				await rpc.send('prompt', {
					message:
						'/loop --passive 30s Reply with one short sentence about the weather.',
				})
				const dir = await loopDir(fixture.state)
				await waitForState(
					dir,
					(state) => state.attempt?.finalized === true && state.iteration === 1,
					5 * 60_000,
				)
				await rpc.send('prompt', {
					message: `/loop send End your reply with the word ${word}.`,
				})
				await waitForState(
					dir,
					(state) => state.attempt?.finalized === true && state.iteration === 2,
					5 * 60_000,
				)
				const latest = await readFile(join(dir, FILES.latest), 'utf8')
				assert.match(latest, new RegExp(word), latest)
				await stopAndClose(rpc)
			} finally {
				rpc.kill()
			}
		}),
)

function processRows(): Promise<
	Array<{pid: number; ppid: number; command: string}>
> {
	return new Promise((resolve, reject) =>
		execFile(
			'ps',
			['-A', '-o', 'pid=', '-o', 'ppid=', '-o', 'command='],
			{env: {...process.env, LC_ALL: 'C'}},
			(error, stdout) =>
				error
					? reject(error)
					: resolve(
							stdout.split('\n').flatMap((line) => {
								const match = line.trim().match(/^(\d+)\s+(\d+)\s+(.*)$/)
								return match
									? [
											{
												pid: Number(match[1]),
												ppid: Number(match[2]),
												command: match[3],
											},
										]
									: []
							}),
						),
		),
	)
}

/** Read-only: the run's child and its `sleep 120` tool process. */
async function runningProcesses(dir: string, fixture: Fixture) {
	const state = await waitForState(
		dir,
		(current) =>
			current.attempt?.phase === 'running' && Boolean(current.attempt.lstart),
		5 * 60_000,
	)
	const child = {
		pid: state.attempt?.pid as number,
		lstart: state.attempt?.lstart as string,
	}
	fixture.recorded.push(child)
	let tool: {pid: number; lstart: string} | undefined
	await waitUntil(async () => {
		const rows = await processRows()
		const below = new Set([child.pid])
		for (let grew = true; grew;) {
			grew = false
			for (const row of rows)
				if (below.has(row.ppid) && !below.has(row.pid)) {
					below.add(row.pid)
					grew = true
				}
		}
		const match = rows.find(
			(row) => below.has(row.pid) && /^sleep 120$/.test(row.command),
		)
		const lstart = match && (await readProcessTable())?.get(match.pid)
		if (match && lstart) tool = {pid: match.pid, lstart}
		return tool !== undefined
	}, 5 * 60_000)
	fixture.recorded.push(tool as {pid: number; lstart: string})
	return {child, tool: tool as {pid: number; lstart: string}}
}

const alive = async (process: {pid: number; lstart: string}) =>
	classifyProcess(await readProcessTable(), process.pid, process.lstart) ===
	'alive'

for (const ending of ['quit', 'kill'] as const)
	test(
		`${ending === 'quit' ? 'quitting' : 'killing'} the owner stops the running child and its tool`,
		{timeout: 10 * 60_000},
		async () =>
			withFixture(async (fixture) => {
				const rpc = await PiRpc.start(OWNER_ARGS, {
					cwd: fixture.root,
					env: fixture.env,
				})
				try {
					await rpc.send('prompt', {
						message:
							'/loop --passive 30s Use the bash tool to run exactly this command: sleep 120. Then reply done.',
					})
					const dir = await loopDir(fixture.state)
					const {child, tool} = await runningProcesses(dir, fixture)
					if (ending === 'quit') assert.equal(await rpc.close(), 0, rpc.stderr)
					else {
						process.kill(rpc.pid as number, 'SIGKILL')
						await rpc.waitForExit()
					}
					await waitUntil(
						async () => !(await alive(child)) && !(await alive(tool)),
						30_000,
					)
				} finally {
					rpc.kill()
				}
			}),
	)
