import assert from 'node:assert/strict'
import {spawnSync} from 'node:child_process'
import {
	mkdir,
	mkdtemp,
	readdir,
	readFile,
	realpath,
	rm,
	writeFile,
} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {dirname, join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import {executable, PiRpc} from '../lib/test-support.ts'
import {MISSING_MODEL_WARNING, NO_VCS_WARNING} from './index.ts'

const INLINE_SLUG = ".trim().toLowerCase().replace(/\\s+/g, '-')"

// Two call sites repeat the normalization an existing helper already does.
const PROJECT: Record<string, string> = {
	'package.json': '{"type": "module"}\n',
	'lib/slug.js': `export function slugify(value) {\n\treturn value${INLINE_SLUG}\n}\n`,
	'src/users.js': `export function userSlug(user) {\n\treturn user.name${INLINE_SLUG}\n}\n`,
	'src/teams.js': `export function teamSlug(team) {\n\treturn \`team-\${team.title${INLINE_SLUG}}\`\n}\n`,
	'check.js': `import assert from 'node:assert/strict'
import {userSlug} from './src/users.js'
import {teamSlug} from './src/teams.js'

assert.equal(userSlug({name: '  Ada   Lovelace '}), 'ada-lovelace')
assert.equal(teamSlug({title: 'Core Platform'}), 'team-core-platform')
`,
}

test(
	'actual pi simplifies a directory without version control through a real model',
	{timeout: 20 * 60_000},
	async () => {
		const root = await realpath(
			await mkdtemp(join(tmpdir(), 'pi-simplify-e2e-')),
		)
		const project = join(root, 'project')
		const tmp = join(root, 'tmp')
		let rpc: PiRpc | undefined
		let passed = false
		try {
			for (const [path, contents] of Object.entries(PROJECT)) {
				await mkdir(dirname(join(project, path)), {recursive: true})
				await writeFile(join(project, path), contents)
			}
			await mkdir(tmp)
			const node = await executable('node')
			const check = () =>
				spawnSync(node, ['check.js'], {cwd: project, encoding: 'utf8'})
			const before = check()
			assert.equal(before.status, 0, before.stderr)

			// Uses the credentials and, unless PI_E2E_MODEL names one, the
			// default model from the real agent directory. The reviewers inherit
			// the environment, so their reports land in the fixture's TMPDIR.
			const model = process.env.PI_E2E_MODEL
			rpc = await PiRpc.start(
				[
					'--no-session',
					'--no-extensions',
					'--no-context-files',
					'--no-skills',
					'--no-prompt-templates',
					'--no-themes',
					'--no-approve',
					'--tools',
					'read,bash,edit,write',
					...(model ? ['--model', model] : []),
					'--thinking',
					'off',
					'--extension',
					dirname(fileURLToPath(import.meta.url)),
				],
				{
					cwd: project,
					env: {...process.env, PI_SKIP_VERSION_CHECK: '1', TMPDIR: tmp},
				},
			)
			await rpc.send('prompt', {message: '/simplify'}, 60_000)
			const outcome = await rpc.waitFor(
				(r) => r.type === 'agent_settled' || r.notifyType === 'error',
				{timeout: 17 * 60_000},
			)
			const notifications = rpc.records
				.filter((r) => r.method === 'notify')
				.map((r) => `${r.notifyType}: ${r.message}`)
			assert.equal(outcome.type, 'agent_settled', notifications.join('\n'))
			assert.deepEqual(notifications, [`warning: ${NO_VCS_WARNING}`])
			assert.ok(
				JSON.stringify(rpc.records).includes(
					'The four /simplify reviewers have finished',
				),
				'the apply turn never started',
			)
			assert.equal(await rpc.close(), 0, rpc.stderr)
			// The real settings' model scope may name models this pi's catalog
			// lacks; pi warns about each and carries on.
			const unexpected = rpc.stderr
				.split('\n')
				.filter((line) => line && !MISSING_MODEL_WARNING.test(line))
			assert.deepEqual(unexpected, [])

			const result = check()
			assert.equal(result.status, 0, result.stderr)
			for (const path of ['src/users.js', 'src/teams.js']) {
				const source = await readFile(join(project, path), 'utf8')
				assert.match(source, /\bslugify\b/, `${path}:\n${source}`)
				assert.ok(!source.includes(INLINE_SLUG), `${path}:\n${source}`)
			}
			const entries = await readdir(project)
			assert.ok(!entries.includes('.git') && !entries.includes('.jj'))
			passed = true
		} finally {
			rpc?.kill()
			if (passed) {
				await rm(root, {recursive: true, force: true})
			} else if (rpc) {
				await writeFile(
					join(root, 'events.jsonl'),
					rpc.records.map((r) => JSON.stringify(r)).join('\n'),
				)
				console.error(`Kept the failed fixture and its events in ${root}`)
			}
		}
	},
)
