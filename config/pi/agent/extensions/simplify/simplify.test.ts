import assert from 'node:assert/strict'
import {spawnSync} from 'node:child_process'
import {
	mkdir,
	mkdtemp,
	readdir,
	readFile,
	realpath,
	rm,
	stat,
	writeFile,
} from 'node:fs/promises'
import {createServer, type IncomingMessage} from 'node:http'
import type {AddressInfo} from 'node:net'
import {tmpdir} from 'node:os'
import {dirname, join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import type {
	ExecResult,
	ExtensionAPI,
	ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'
import {
	PiRpc,
	ScriptedModel,
	type RpcRecord,
	type ScriptedReply,
	type ScriptedRequest,
} from '../lib/test-support.ts'
import simplify, {
	applyPrompt,
	isVersioned,
	NO_VCS_WARNING,
	REVIEWERS,
	reviewerOutput,
	reviewerPrompt,
	reviewPaths,
	runReviews,
} from './index.ts'

const EXTENSION = dirname(fileURLToPath(import.meta.url))
const NAMES = Object.keys(REVIEWERS).sort()
// What pi prints for an `enabledModels` entry its catalog lacks.
const MISSING_MODEL = 'Warning: No models match pattern "xai/grok-4.7"'

type Exec = ExtensionAPI['exec']
type Handler = (args: string, ctx: ExtensionCommandContext) => Promise<void>

const result = (fields: Partial<ExecResult> = {}): ExecResult => ({
	stdout: '',
	stderr: '',
	code: 0,
	killed: false,
	...fields,
})

const assistantEnd = (
	text: string,
	stopReason = 'stop',
	errorMessage?: string,
) =>
	JSON.stringify({
		type: 'message_end',
		message: {
			role: 'assistant',
			stopReason,
			errorMessage,
			content: [{type: 'text', text}],
		},
	})

const reviewerName = (argv: string[]) =>
	/You are the (\w+) reviewer/.exec(argv.at(-1) ?? '')?.[1] ?? ''

/** Answers each reviewer with a report naming it; jj and git fail. */
const reviewersExec =
	(calls: {command: string; argv: string[]; cwd?: string}[] = []): Exec =>
	async (command, argv, options) => {
		calls.push({command, argv, cwd: options?.cwd})
		if (command !== 'pi') return result({code: 1})
		return result({stdout: assistantEnd(`${reviewerName(argv)} report`) + '\n'})
	}

/** Blocks each reviewer until its signal aborts, as a killed child would. */
const hangingExec =
	(started: AbortSignal[]): Exec =>
	(command, _argv, options) => {
		if (command !== 'pi') return Promise.resolve(result({code: 1}))
		const signal = options?.signal
		assert.ok(signal)
		started.push(signal)
		return new Promise((resolve) =>
			signal.addEventListener('abort', () =>
				resolve(result({code: 143, killed: true})),
			),
		)
	}

function fakePi(exec: Exec) {
	const commands = new Map<string, Handler>()
	const events = new Map<string, () => void>()
	const sent: {message: string; options: unknown}[] = []
	const pi = {
		exec,
		on: (name: string, handler: () => void) => events.set(name, handler),
		registerCommand: (name: string, command: {handler: Handler}) =>
			commands.set(name, command.handler),
		sendUserMessage: (message: string, options: unknown) =>
			sent.push({message, options}),
	} as unknown as ExtensionAPI
	simplify(pi)
	const handler = commands.get('simplify')
	assert.ok(handler, 'simplify command not registered')
	return {pi, handler, events, sent}
}

function fakeCtx(cwd: string, overrides: Record<string, unknown> = {}) {
	const notifications: string[] = []
	const statuses: (string | undefined)[] = []
	const ctx = {
		cwd,
		hasUI: true,
		isIdle: () => true,
		model: {provider: 'prov', id: 'mod'},
		thinkingLevel: 'high',
		ui: {
			notify: (message: string, type: string) =>
				notifications.push(`${type}: ${message}`),
			setStatus: (_key: string, text: string | undefined) =>
				statuses.push(text),
		},
		...overrides,
	} as unknown as ExtensionCommandContext
	return {ctx, notifications, statuses}
}

/** Point os.tmpdir(), and so the report directory, at a fresh directory. */
async function withTmp(run: (tmp: string) => Promise<void>): Promise<void> {
	const tmp = await realpath(await mkdtemp(join(tmpdir(), 'pi-simplify-test-')))
	const previous = process.env.TMPDIR
	process.env.TMPDIR = tmp
	try {
		await run(tmp)
	} finally {
		if (previous === undefined) delete process.env.TMPDIR
		else process.env.TMPDIR = previous
		await rm(tmp, {recursive: true, force: true})
	}
}

const waitUntil = async (check: () => boolean, timeout = 10_000) => {
	const deadline = Date.now() + timeout
	while (!check()) {
		if (Date.now() > deadline) throw new Error('Timed out waiting')
		await new Promise((resolve) => setTimeout(resolve, 10))
	}
}

test('review paths default to the current directory and must exist', async () => {
	const root = await realpath(
		await mkdtemp(join(tmpdir(), 'pi-simplify-paths-')),
	)
	try {
		await mkdir(join(root, 'src'))
		await writeFile(join(root, 'with space.ts'), '')
		assert.deepEqual(await reviewPaths(root, ''), ['.'])
		assert.deepEqual(await reviewPaths(root, '   '), ['.'])
		assert.deepEqual(await reviewPaths(root, 'src "with space.ts"'), [
			'src',
			'with space.ts',
		])
		assert.deepEqual(await reviewPaths(root, `'with space.ts'`), [
			'with space.ts',
		])
		await assert.rejects(reviewPaths(root, 'src nope'), {
			message: 'Path not found: nope',
		})
		await assert.rejects(reviewPaths(root, '"src'), /Unclosed quote/)
	} finally {
		await rm(root, {recursive: true, force: true})
	}
})

test('reviewer output is the final assistant text', () => {
	const stream = [
		JSON.stringify({type: 'message_start'}),
		assistantEnd('first'),
		'',
		assistantEnd('final findings'),
	].join('\n')
	assert.equal(reviewerOutput(stream), 'final findings')
	assert.throws(() => reviewerOutput(''), {
		message: 'Reviewer did not finish: no assistant response',
	})
	assert.throws(() => reviewerOutput(assistantEnd('partial', 'length')), {
		message: 'Reviewer did not finish: length',
	})
	assert.throws(
		() => reviewerOutput(assistantEnd('', 'error', 'provider exploded')),
		{message: 'provider exploded'},
	)
	assert.throws(() => reviewerOutput(assistantEnd('  ')), {
		message: 'Reviewer returned no findings or clean verdict',
	})
	assert.throws(() => reviewerOutput('not json'), SyntaxError)
})

test('prompts name the reviewed paths instead of a diff', () => {
	const paths = ['.', 'src/with "quotes".ts']
	const reviewer = reviewerPrompt('reuse', REVIEWERS.reuse, paths)
	assert.match(reviewer, /^You are the reuse reviewer/)
	assert.ok(reviewer.includes(`Your angle: ${REVIEWERS.reuse}`))
	assert.ok(reviewer.includes('- "."\n- "src/with \\"quotes\\".ts"'))
	const apply = applyPrompt({
		directory: '/tmp/pi-simplify-x',
		paths,
		reports: ['/tmp/pi-simplify-x/reuse.md'],
	})
	assert.ok(apply.includes('- "/tmp/pi-simplify-x/reuse.md"'))
	assert.ok(apply.includes('- "."\n- "src/with \\"quotes\\".ts"'))
	for (const prompt of [reviewer, apply, ...Object.values(REVIEWERS)]) {
		assert.doesNotMatch(prompt, /\b(diff|patch)\b/i)
	}
})

test('version control detection covers jj, git, and plain directories', async () => {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-simplify-vcs-')))
	const exec: Exec = async (command, argv, options) => {
		const child = spawnSync(command, argv, {
			cwd: options?.cwd,
			encoding: 'utf8',
		})
		return result({
			stdout: child.stdout ?? '',
			stderr: child.stderr ?? '',
			code: child.status ?? 1,
		})
	}
	const pi = {exec} as unknown as ExtensionAPI
	const run = (cwd: string, command: string, ...argv: string[]) => {
		const child = spawnSync(command, argv, {cwd, encoding: 'utf8'})
		assert.equal(child.status, 0, child.stderr)
	}
	try {
		const plain = join(root, 'plain')
		const git = join(root, 'git')
		const jj = join(root, 'jj')
		await Promise.all(
			[plain, git, jj].map((dir) => mkdir(join(dir, 'sub'), {recursive: true})),
		)
		run(git, 'git', 'init', '-q')
		run(jj, 'jj', 'git', 'init', '--no-colocate', '--quiet')
		assert.equal(await isVersioned(pi, join(plain, 'sub')), false)
		assert.equal(await isVersioned(pi, join(git, 'sub')), true)
		assert.equal(await isVersioned(pi, join(jj, 'sub')), true)
	} finally {
		await rm(root, {recursive: true, force: true})
	}
})

test('runs four reviewers concurrently with the session model', () =>
	withTmp(async (tmp) => {
		const calls: {argv: string[]; cwd?: string; signal?: AbortSignal}[] = []
		let inFlight = 0
		let peak = 0
		const exec: Exec = async (_command, argv, options) => {
			calls.push({argv, cwd: options?.cwd, signal: options?.signal})
			inFlight++
			peak = Math.max(peak, inFlight)
			await waitUntil(() => calls.length === 4)
			inFlight--
			return result({stdout: assistantEnd(`${reviewerName(argv)} report`)})
		}
		const {ctx} = fakeCtx('/work/app')
		const progress: number[] = []
		const signal = new AbortController().signal
		const bundle = await runReviews(
			{exec} as unknown as ExtensionAPI,
			ctx,
			['src'],
			signal,
			(completed) => progress.push(completed),
		)

		assert.equal(peak, 4)
		assert.deepEqual(progress, [1, 2, 3, 4])
		assert.deepEqual(calls.map((call) => reviewerName(call.argv)).sort(), NAMES)
		for (const call of calls) {
			assert.equal(call.cwd, '/work/app')
			assert.equal(call.signal, signal)
			const prompt = call.argv.at(-1)
			assert.deepEqual(call.argv.slice(0, -1), [
				'--mode',
				'json',
				'--print',
				'--no-session',
				'--offline',
				'--no-extensions',
				'--no-skills',
				'--no-prompt-templates',
				'--no-themes',
				'--tools',
				'read,bash',
				'--model',
				'prov/mod',
				'--thinking',
				'high',
				'--',
			])
			const name = reviewerName(call.argv) as keyof typeof REVIEWERS
			assert.equal(prompt, reviewerPrompt(name, REVIEWERS[name], ['src']))
		}
		assert.equal(dirname(bundle.directory), tmp)
		assert.deepEqual(bundle.paths, ['src'])
		assert.deepEqual(
			bundle.reports.map((path) => dirname(path)),
			Array(4).fill(bundle.directory),
		)
		for (const report of bundle.reports) {
			const name = report.slice(bundle.directory.length + 1, -'.md'.length)
			assert.equal(await readFile(report, 'utf8'), `${name} report`)
			assert.equal((await stat(report)).mode & 0o777, 0o600)
		}
	}))

test('omits --thinking when the model exposes no level', () =>
	withTmp(async () => {
		const calls: {command: string; argv: string[]}[] = []
		const {ctx} = fakeCtx('/work', {thinkingLevel: undefined})
		await runReviews(
			{exec: reviewersExec(calls)} as unknown as ExtensionAPI,
			ctx,
			['.'],
			new AbortController().signal,
			() => {},
		)
		assert.equal(calls.length, 4)
		for (const {argv} of calls) {
			assert.equal(argv.includes('--thinking'), false)
			assert.deepEqual(argv.slice(-4, -1), ['--model', 'prov/mod', '--'])
		}
	}))

test('reviewer failures stop the run and remove the reports', async () => {
	const cases: {name: string; fail: ExecResult; message: RegExp}[] = [
		{
			name: 'exit code',
			fail: result({code: 2, stderr: 'boom\n'}),
			message: /^Error: efficiency: boom$/,
		},
		{
			name: 'silent exit code',
			fail: result({code: 3}),
			message: /^Error: efficiency: pi exited with code 3$/,
		},
		{
			name: 'timeout',
			fail: result({code: 143, killed: true}),
			message:
				/^Error: efficiency: pi exited with code 143 \(killed or timed out\)$/,
		},
		{
			name: 'stderr diagnostics',
			fail: result({stdout: assistantEnd('ok'), stderr: 'Warning: odd\n'}),
			message: /^Error: efficiency: Warning: odd$/,
		},
		{
			name: 'incomplete response',
			fail: result({stdout: assistantEnd('cut', 'length')}),
			message: /^Error: efficiency: Reviewer did not finish: length$/,
		},
		{
			name: 'stderr beyond missing-model warnings',
			fail: result({
				stdout: assistantEnd('ok'),
				stderr: `${MISSING_MODEL}\nWarning: odd\n`,
			}),
			message: /^Error: efficiency: Warning: odd$/,
		},
		{
			name: 'exit code after a missing-model warning',
			fail: result({code: 1, stderr: `${MISSING_MODEL}\nboom\n`}),
			message: /^Error: efficiency: boom$/,
		},
		{
			name: 'exit code with only a missing-model warning',
			fail: result({code: 1, stderr: `${MISSING_MODEL}\n`}),
			message: /^Error: efficiency: pi exited with code 1$/,
		},
	]
	for (const {name, fail, message} of cases) {
		await withTmp(async (tmp) => {
			const exec: Exec = async (command, argv, options) =>
				reviewerName(argv) === 'efficiency'
					? fail
					: reviewersExec()(command, argv, options)
			const {ctx} = fakeCtx('/work')
			await assert.rejects(
				runReviews(
					{exec} as unknown as ExtensionAPI,
					ctx,
					['.'],
					new AbortController().signal,
					() => {},
				),
				(error: Error) => {
					assert.match(error.message, message, name)
					return true
				},
			)
			assert.deepEqual(await readdir(tmp), [], name)
		})
	}
})

test('ignores missing-model warnings from reviewers', () =>
	withTmp(async () => {
		const exec: Exec = async (_command, argv) =>
			result({
				stdout: assistantEnd(`${reviewerName(argv)} report`),
				stderr: `${MISSING_MODEL}\nWarning: No models match pattern "other/*"\n`,
			})
		const {ctx} = fakeCtx('/work')
		const bundle = await runReviews(
			{exec} as unknown as ExtensionAPI,
			ctx,
			['.'],
			new AbortController().signal,
			() => {},
		)
		assert.deepEqual(
			(
				await Promise.all(bundle.reports.map((path) => readFile(path, 'utf8')))
			).sort(),
			NAMES.map((name) => `${name} report`),
		)
	}))

test('requires a selected model before starting reviewers', () =>
	withTmp(async (tmp) => {
		const calls: {command: string; argv: string[]}[] = []
		const {ctx} = fakeCtx('/work', {model: undefined})
		await assert.rejects(
			runReviews(
				{exec: reviewersExec(calls)} as unknown as ExtensionAPI,
				ctx,
				['.'],
				new AbortController().signal,
				() => {},
			),
			{message: 'Select a model before running /simplify'},
		)
		assert.deepEqual(calls, [])
		assert.deepEqual(await readdir(tmp), [])
	}))

test('aborting kills the reviewers and removes the reports', () =>
	withTmp(async (tmp) => {
		const started: AbortSignal[] = []
		const controller = new AbortController()
		const {ctx} = fakeCtx('/work')
		const run = runReviews(
			{exec: hangingExec(started)} as unknown as ExtensionAPI,
			ctx,
			['.'],
			controller.signal,
			() => {},
		)
		await waitUntil(() => started.length === 4)
		controller.abort()
		await assert.rejects(run, {name: 'AbortError'})
		assert.ok(started.every((signal) => signal.aborted))
		assert.deepEqual(await readdir(tmp), [])
	}))

test('the command hands the reports to the parent without warning in a repository', () =>
	withTmp(async () => {
		const calls: {command: string; argv: string[]; cwd?: string}[] = []
		const base = reviewersExec(calls)
		const exec: Exec = async (command, argv, options) =>
			command === 'jj'
				? (calls.push({command, argv, cwd: options?.cwd}),
					result({stdout: '/repo\n'}))
				: base(command, argv, options)
		const {handler, sent} = fakePi(exec)
		const {ctx, notifications, statuses} = fakeCtx(EXTENSION)
		await handler('', ctx)

		assert.deepEqual(notifications, [])
		assert.deepEqual(
			calls.filter((call) => call.command !== 'pi').map((call) => call.command),
			['jj'],
		)
		assert.deepEqual(statuses, [
			'Simplify: 0/4 reviewers finished',
			'Simplify: 1/4 reviewers finished',
			'Simplify: 2/4 reviewers finished',
			'Simplify: 3/4 reviewers finished',
			'Simplify: 4/4 reviewers finished',
			undefined,
		])
		assert.equal(sent.length, 1)
		assert.deepEqual(sent[0].options, {deliverAs: 'followUp'})
		assert.match(
			sent[0].message,
			/^The four \/simplify reviewers have finished/,
		)
		const reports = [...sent[0].message.matchAll(/"([^"]+\.md)"/g)].map(
			(match) => match[1],
		)
		assert.equal(reports.length, 4)
		assert.deepEqual(
			(await Promise.all(reports.map((path) => readFile(path, 'utf8')))).sort(),
			NAMES.map((name) => `${name} report`),
		)
	}))

test('the command warns outside version control and still applies', () =>
	withTmp(async () => {
		const calls: {command: string; argv: string[]}[] = []
		const {handler, sent} = fakePi(reviewersExec(calls))
		const {ctx, notifications} = fakeCtx(EXTENSION)
		await handler('', ctx)
		assert.deepEqual(notifications, [`warning: ${NO_VCS_WARNING}`])
		assert.deepEqual(
			calls.slice(0, 2).map((call) => call.command),
			['jj', 'git'],
		)
		assert.equal(sent.length, 1)
	}))

test('the command rejects a missing path before any reviewer starts', () =>
	withTmp(async () => {
		const calls: {command: string; argv: string[]}[] = []
		const {handler, sent} = fakePi(reviewersExec(calls))
		const {ctx, notifications, statuses} = fakeCtx(EXTENSION)
		await handler('index.ts nope', ctx)
		assert.deepEqual(notifications, [
			'error: Simplify failed: Path not found: nope',
		])
		assert.deepEqual(calls, [])
		assert.deepEqual(sent, [])
		assert.equal(statuses.at(-1), undefined)
	}))

test('the command reports reviewer failures without an apply turn', () =>
	withTmp(async () => {
		const exec: Exec = async (command, argv, options) =>
			reviewerName(argv) === 'altitude'
				? result({code: 1, stderr: 'no credentials'})
				: reviewersExec()(command, argv, options)
		const {handler, sent} = fakePi(exec)
		const {ctx, notifications} = fakeCtx(EXTENSION)
		await handler('', ctx)
		assert.deepEqual(notifications, [
			`warning: ${NO_VCS_WARNING}`,
			'error: Simplify failed: Error: altitude: no credentials',
		])
		assert.deepEqual(sent, [])
	}))

test('the command guards modes, busy sessions, and cancellation', () =>
	withTmp(async (tmp) => {
		const started: AbortSignal[] = []
		const {handler, sent, events} = fakePi(hangingExec(started))

		const headless = fakeCtx(EXTENSION, {hasUI: false})
		await assert.rejects(handler('', headless.ctx), {
			message: '/simplify requires an interactive or RPC session',
		})

		const busy = fakeCtx(EXTENSION, {isIdle: () => false})
		await handler('', busy.ctx)
		assert.deepEqual(busy.notifications, [
			'warning: Wait for the current work to finish, or use /simplify cancel',
		])

		const idle = fakeCtx(EXTENSION)
		await handler('cancel', idle.ctx)
		assert.deepEqual(idle.notifications, [
			'info: No simplify review is running',
		])

		const first = fakeCtx(EXTENSION)
		const run = handler('', first.ctx)
		await waitUntil(() => started.length === 4)
		const second = fakeCtx(EXTENSION)
		await handler('', second.ctx)
		assert.deepEqual(second.notifications, [
			'warning: Wait for the current work to finish, or use /simplify cancel',
		])
		await handler('cancel', second.ctx)
		await run
		assert.ok(started.every((signal) => signal.aborted))
		assert.deepEqual(first.notifications, [
			`warning: ${NO_VCS_WARNING}`,
			'info: Simplify cancelled; no fixes were requested',
		])
		assert.equal(first.statuses.at(-1), undefined)
		assert.deepEqual(await readdir(tmp), [])

		// Shutdown aborts silently: the session is going away.
		const shutdown = fakeCtx(EXTENSION)
		const stopped = handler('', shutdown.ctx)
		await waitUntil(() => started.length === 8)
		events.get('session_shutdown')?.()
		await stopped
		assert.ok(started.slice(4).every((signal) => signal.aborted))
		assert.deepEqual(shutdown.notifications, [`warning: ${NO_VCS_WARNING}`])
		assert.deepEqual(sent, [])
		assert.deepEqual(await readdir(tmp), [])
	}))

const RPC_ARGS = [
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

interface Fixture {
	root: string
	project: string
	tmp: string
	env: NodeJS.ProcessEnv
}

/**
 * An isolated agent directory whose only model is `scripted/test` at
 * `modelsJson`. The reviewer subprocesses inherit the environment, so they
 * reach the same endpoint. Retries are off so a refused request fails fast.
 */
async function withFixture(
	modelsJson: string,
	run: (fixture: Fixture) => Promise<void>,
	settings: Record<string, unknown> = {},
): Promise<void> {
	const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-simplify-rpc-')))
	try {
		const agent = join(root, 'agent')
		const project = join(root, 'project')
		const tmp = join(root, 'tmp')
		await Promise.all([agent, project, tmp].map((dir) => mkdir(dir)))
		await writeFile(join(agent, 'models.json'), modelsJson)
		await writeFile(
			join(agent, 'settings.json'),
			JSON.stringify({retry: {enabled: false}, ...settings}),
		)
		await mkdir(join(project, 'src'))
		await writeFile(join(project, 'src', 'app.ts'), 'export const app = 1\n')
		await run({
			root,
			project,
			tmp,
			env: {
				PATH: process.env.PATH ?? '',
				HOME: root,
				XDG_CONFIG_HOME: join(root, 'config'),
				XDG_STATE_HOME: join(root, 'state'),
				PI_CODING_AGENT_DIR: agent,
				PI_OFFLINE: '1',
				PI_SKIP_VERSION_CHECK: '1',
				TMPDIR: tmp,
			},
		})
	} finally {
		await rm(root, {recursive: true, force: true})
	}
}

// Pi keeps its own caches (jiti) in TMPDIR, so look for reports only.
const reportDirectories = async (tmp: string) =>
	(await readdir(tmp)).filter((name) => name.startsWith('pi-simplify-'))

const notifications = (records: RpcRecord[]) =>
	records
		.filter((r) => r.type === 'extension_ui_request' && r.method === 'notify')
		.map((r) => `${r.notifyType}: ${r.message}`)

const lastUserText = (request: ScriptedRequest) => {
	const message = request.messages.at(-1)
	assert.ok(message?.role === 'user', JSON.stringify(message))
	const content = message.content
	return typeof content === 'string'
		? content
		: (content as {text?: string}[]).map((part) => part.text ?? '').join('')
}

const reviewReplies = (): ScriptedReply[] =>
	NAMES.map((_, index) => ({text: `finding ${index + 1}`}))

/** Run /simplify in actual pi and wait until the apply turn settles. */
async function simplifyThroughApply(
	fixture: Fixture,
	model: ScriptedModel,
	message: string,
	stderr = '',
): Promise<string[]> {
	const rpc = await PiRpc.start(RPC_ARGS, {
		cwd: fixture.project,
		env: fixture.env,
	})
	try {
		await rpc.send('prompt', {message}, 60_000)
		const outcome = await rpc.waitFor(
			(r) => r.type === 'agent_settled' || r.notifyType === 'error',
			{timeout: 60_000},
		)
		assert.equal(outcome.type, 'agent_settled', outcome.message ?? '')
		assert.equal(await rpc.close(), 0, rpc.stderr)
		assert.equal(rpc.stderr, stderr)
		assert.equal(model.requests.length, 5)
		return notifications(rpc.records)
	} finally {
		rpc.kill()
	}
}

/** Checks the four reviewer requests and the apply request pi sent. */
async function assertReviewedThenApplied(
	model: ScriptedModel,
	paths: string[],
): Promise<void> {
	const listed = paths.map((path) => `- ${JSON.stringify(path)}`).join('\n')
	const reviewers = model.requests.slice(0, 4).map(lastUserText)
	assert.deepEqual(
		reviewers
			.map((text) => /You are the (\w+) reviewer/.exec(text)?.[1])
			.sort(),
		NAMES,
	)
	for (const text of reviewers) assert.ok(text.includes(listed), text)

	const apply = lastUserText(model.requests[4])
	assert.match(apply, /^The four \/simplify reviewers have finished/)
	assert.ok(apply.includes(listed), apply)
	const reports = [...apply.matchAll(/"([^"]+\.md)"/g)].map((m) => m[1])
	assert.equal(reports.length, 4)
	assert.deepEqual(
		(await Promise.all(reports.map((path) => readFile(path, 'utf8')))).sort(),
		reviewReplies().map((reply) => (reply as {text: string}).text),
	)
}

test(
	'actual pi reviews a plain directory with a warning, then applies',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			...reviewReplies(),
			{text: 'Applied.'},
		])
		try {
			await withFixture(model.modelsJson, async (fixture) => {
				assert.deepEqual(
					await simplifyThroughApply(fixture, model, '/simplify'),
					[`warning: ${NO_VCS_WARNING}`],
				)
				await assertReviewedThenApplied(model, ['.'])
			})
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi reviewers tolerate a stale enabledModels pattern',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			...reviewReplies(),
			{text: 'Applied.'},
		])
		try {
			await withFixture(
				model.modelsJson,
				async (fixture) => {
					// The parent prints the same warning the reviewers do.
					assert.deepEqual(
						await simplifyThroughApply(
							fixture,
							model,
							'/simplify',
							`${MISSING_MODEL}\n`,
						),
						[`warning: ${NO_VCS_WARNING}`],
					)
					await assertReviewedThenApplied(model, ['.'])
				},
				{enabledModels: ['scripted/test', 'xai/grok-4.7']},
			)
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi reviews paths in a Git repository without a warning',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			...reviewReplies(),
			{text: 'Applied.'},
		])
		try {
			await withFixture(model.modelsJson, async (fixture) => {
				const git = spawnSync('git', ['init', '-q'], {cwd: fixture.project})
				assert.equal(git.status, 0, String(git.stderr))
				assert.deepEqual(
					await simplifyThroughApply(
						fixture,
						model,
						'/simplify src "src/app.ts"',
					),
					[],
				)
				await assertReviewedThenApplied(model, ['src', 'src/app.ts'])
			})
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi reviews a Jujutsu repository without a warning',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			...reviewReplies(),
			{text: 'Applied.'},
		])
		try {
			await withFixture(model.modelsJson, async (fixture) => {
				const jj = spawnSync(
					'jj',
					['git', 'init', '--no-colocate', '--quiet'],
					{cwd: fixture.project, env: fixture.env},
				)
				assert.equal(jj.status, 0, String(jj.stderr))
				assert.deepEqual(
					await simplifyThroughApply(fixture, model, '/simplify'),
					[],
				)
				await assertReviewedThenApplied(model, ['.'])
			})
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi stops on a missing path or a failed reviewer',
	{timeout: 120_000},
	async () => {
		const model = await ScriptedModel.start([
			{text: 'finding 1'},
			{text: 'finding 2'},
			{text: 'finding 3'},
			{status: 500},
		])
		try {
			await withFixture(model.modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(RPC_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					const missing = rpc.records.length
					await rpc.send('prompt', {message: '/simplify nope'})
					await rpc.waitFor((r) => r.notifyType === 'error', {from: missing})
					assert.deepEqual(notifications(rpc.records.slice(missing)), [
						'error: Simplify failed: Path not found: nope',
					])
					assert.equal(model.requests.length, 0)

					const failing = rpc.records.length
					await rpc.send('prompt', {message: '/simplify'})
					await rpc.waitFor((r) => r.notifyType === 'error', {
						from: failing,
						timeout: 60_000,
					})
					const [warning, failure, ...rest] = notifications(
						rpc.records.slice(failing),
					)
					assert.equal(warning, `warning: ${NO_VCS_WARNING}`)
					assert.match(failure, /^error: Simplify failed: Error: (\w+): /)
					assert.deepEqual(rest, [])
					assert.equal(model.requests.length, 4)
					assert.deepEqual(await reportDirectories(fixture.tmp), [])
					assert.equal(await rpc.close(), 0, rpc.stderr)
					assert.equal(rpc.stderr, '')
					assert.equal(model.requests.length, 4)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			model.close()
		}
	},
)

test(
	'actual pi cancels running reviewers and kills their processes',
	{timeout: 120_000},
	async () => {
		// Accepts model requests and never answers, so reviewers stay running
		// until /simplify cancel kills them and their connections close.
		const open = new Set<IncomingMessage>()
		let accepted = 0
		let closed = 0
		const server = createServer((request) => {
			accepted++
			open.add(request)
			request.socket.once('close', () => {
				closed++
				open.delete(request)
			})
		})
		await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve))
		const {port} = server.address() as AddressInfo
		const modelsJson = JSON.stringify({
			providers: {
				scripted: {
					baseUrl: `http://127.0.0.1:${port}/v1`,
					api: 'openai-completions',
					apiKey: 'dummy',
					models: [{id: 'test'}],
				},
			},
		})
		try {
			await withFixture(modelsJson, async (fixture) => {
				const rpc = await PiRpc.start(RPC_ARGS, {
					cwd: fixture.project,
					env: fixture.env,
				})
				try {
					const running = rpc.send('prompt', {message: '/simplify'}, 60_000)
					await waitUntil(() => accepted === 4, 60_000)
					const from = rpc.records.length
					await rpc.send('prompt', {message: '/simplify cancel'})
					await rpc.waitFor(
						(r) => r.method === 'notify' && r.notifyType === 'info',
						{from},
					)
					await running
					await waitUntil(() => closed === 4, 30_000)
					assert.deepEqual(notifications(rpc.records), [
						`warning: ${NO_VCS_WARNING}`,
						'info: Simplify cancelled; no fixes were requested',
					])
					assert.deepEqual(await reportDirectories(fixture.tmp), [])
					assert.equal(await rpc.close(), 0, rpc.stderr)
					assert.equal(rpc.stderr, '')
					assert.equal(accepted, 4)
				} finally {
					rpc.kill()
				}
			})
		} finally {
			for (const request of open) request.socket.destroy()
			server.close()
		}
	},
)
