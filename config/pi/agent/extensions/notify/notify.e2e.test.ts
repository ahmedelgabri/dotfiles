import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {mkdtemp, realpath, rm} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {test} from 'node:test'
import {fileURLToPath} from 'node:url'
import {withoutPaneIdentity} from '../lib/pane-identity.ts'
import {executable} from '../lib/test-support.ts'

// Uses the real agent directory, credentials, and model (PI_E2E_MODEL, or
// the default), as an unattended run such as a /loop child would.
test(
	'a real print-mode run writes no notification escapes',
	{timeout: 5 * 60_000},
	async () => {
		const root = await realpath(await mkdtemp(join(tmpdir(), 'pi-notify-e2e-')))
		try {
			const model = process.env.PI_E2E_MODEL
			const child = spawn(
				await executable('pi'),
				[
					'--no-session',
					'--no-extensions',
					'--no-context-files',
					'--no-skills',
					'--no-prompt-templates',
					'--no-themes',
					'--no-tools',
					...(model ? ['--model', model] : []),
					'--thinking',
					'off',
					'--extension',
					fileURLToPath(new URL('./index.ts', import.meta.url)),
					'-p',
					'Reply with exactly the word ready and nothing else.',
				],
				{
					cwd: root,
					// Inside Rex, an inherited REX_SESSION would silence the extension
					// and let the test pass for the wrong reason.
					env: {
						...withoutPaneIdentity(process.env),
						PI_SKIP_VERSION_CHECK: '1',
						TMPDIR: root,
					},
					// pi -p reads piped stdin until EOF, so stdin must not be a pipe.
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
			const code = await new Promise((resolve) => child.once('close', resolve))
			assert.equal(code, 0, stderr)
			// Outside the TUI, Pi moves extension stdout writes to stderr.
			assert.equal(stdout.includes('\x1b'), false, JSON.stringify(stdout))
			assert.equal(stderr.includes('\x1b'), false, JSON.stringify(stderr))
			assert.match(stdout, /ready/i)
		} finally {
			await rm(root, {recursive: true, force: true})
		}
	},
)
