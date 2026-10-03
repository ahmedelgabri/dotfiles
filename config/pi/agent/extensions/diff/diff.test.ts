import {afterEach, beforeEach, test} from 'node:test'
import assert from 'node:assert/strict'
import {spawnSync} from 'node:child_process'
import {
	mkdtemp,
	mkdir,
	readFile,
	readdir,
	realpath,
	rename,
	rm,
	symlink,
	writeFile,
} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {dirname, join} from 'node:path'
import {
	annotationStoreKey,
	annotationStorePath,
	loadPersistedAnnotations,
	savePersistedAnnotations,
	type StoredReviewAnnotation,
} from './annotations-store.ts'
import {renderHtml} from './html.ts'
import {coerceUiPrefs, loadUiPrefs, saveUiPrefs} from './prefs.ts'
import {
	createDiffSnapshotLoader,
	loadConflictFiles,
	saveConflictFile,
	type DiffSnapshot,
} from './vcs.ts'

type Pi = Parameters<typeof createDiffSnapshotLoader>[0]
type Context = Parameters<typeof createDiffSnapshotLoader>[1]
let root: string
let savedEnv: NodeJS.ProcessEnv
let env: NodeJS.ProcessEnv
beforeEach(async () => {
	root = await realpath(await mkdtemp(join(tmpdir(), 'pi-diff-test-')))
	savedEnv = {...process.env}
	process.env.PI_CODING_AGENT_DIR = join(root, 'agent')
	process.env.PI_DIFF_ANNOTATIONS_DIR = join(root, 'annotations')
	process.env.PI_DIFF_ANNOTATIONS_PATH = join(root, 'legacy.json')
	process.env.PI_DIFF_PREFS_PATH = join(root, 'prefs.json')
	env = {
		...process.env,
		HOME: root,
		XDG_CONFIG_HOME: root,
		JJ_CONFIG: '/dev/null',
		GIT_CONFIG_GLOBAL: '/dev/null',
		GIT_CONFIG_NOSYSTEM: '1',
	}
})
afterEach(async () => {
	for (const key of [
		'PI_CODING_AGENT_DIR',
		'PI_DIFF_ANNOTATIONS_DIR',
		'PI_DIFF_ANNOTATIONS_PATH',
		'PI_DIFF_PREFS_PATH',
	]) {
		if (savedEnv[key] === undefined) delete process.env[key]
		else process.env[key] = savedEnv[key]
	}
	await rm(root, {recursive: true, force: true})
})

function snapshot(repoRoot = root): DiffSnapshot {
	return {
		vcs: 'jj',
		repoRoot,
		cwd: repoRoot,
		command: 'jj diff --git',
		patch: '',
		files: [],
		source: {
			kind: 'working',
			key: 'working:jj:jj diff --git',
			label: 'Working diff',
		},
	}
}
const annotation: StoredReviewAnnotation = {
	id: 'a-test',
	path: 'src/file.ts',
	side: 'additions',
	start: 2,
	end: 4,
	endSide: 'additions',
	text: 'Review this',
	author: 'user',
	createdAt: '2026-01-01T00:00:00Z',
	replies: [
		{
			id: 'r-test',
			text: 'Reviewed',
			author: 'pi',
			createdAt: '2026-01-01T01:00:00Z',
		},
	],
}

function run(command: string, args: string[], cwd = root) {
	const result = spawnSync(command, args, {
		cwd,
		env,
		encoding: 'utf8',
		timeout: 30_000,
	})
	if (result.error) throw result.error
	return {
		stdout: result.stdout,
		stderr: result.stderr,
		code: result.status ?? 1,
		killed: false,
	}
}
function jj(cwd: string, ...args: string[]) {
	const result = run(
		'jj',
		[
			'--config',
			'user.name=Test',
			'--config',
			'user.email=test@example.invalid',
			'--config',
			'signing.behavior=drop',
			...args,
		],
		cwd,
	)
	assert.equal(result.code, 0, result.stderr)
	return result.stdout.trim()
}
const realPi = {
	exec: async (command: string, args: string[], options: {cwd: string}) =>
		run(command, args, options.cwd),
} as Pi

async function repo(filename = 'file.txt') {
	const path = join(root, 'repo')
	await mkdir(path)
	jj(path, 'git', 'init', '--colocate')
	await writeFile(join(path, filename), 'base\n')
	jj(path, 'describe', '-m', 'base')
	jj(path, 'bookmark', 'create', 'main')
	jj(path, 'new')
	return path
}

function patchPi(patch: string, calls: string[][] = []): Pi {
	return {
		exec: async (command: string, args: string[]) => {
			calls.push([command, ...args])
			if (command === 'jj')
				return {code: 1, stdout: '', stderr: '', killed: false}
			return {
				code: 0,
				stdout:
					args[0] === 'diff'
						? patch
						: args.includes('--show-toplevel')
							? root
							: 'abc123',
				stderr: '',
				killed: false,
			}
		},
	} as Pi
}

test('parses added, deleted, modified, renamed, copied, and quoted paths', async () => {
	const patch = [
		'diff --git a/new.ts b/new.ts\nnew file mode 100644',
		'diff --git a/old.ts b/old.ts\ndeleted file mode 100644',
		'diff --git a/file.ts b/file.ts\n--- a/file.ts\n+++ b/file.ts',
		'diff --git a/before.ts b/after.ts\nrename from before.ts\nrename to after.ts',
		'diff --git a/source.ts b/copy.ts\ncopy from source.ts\ncopy to copy.ts',
		'diff --git "a/tab\\tname.ts" "b/tab\\tname.ts"\nnew file mode 100644',
	].join('\n')
	const result = await createDiffSnapshotLoader(
		patchPi(patch),
		{cwd: root} as Context,
		'--',
	)()
	assert.deepEqual(
		result.files.map(({path, status}) => [path, status]),
		[
			['new.ts', 'added'],
			['old.ts', 'deleted'],
			['file.ts', 'modified'],
			['after.ts', 'renamed'],
			['copy.ts', 'copied'],
			['tab\tname.ts', 'added'],
		],
	)
	assert.equal(result.files[3].previousPath, 'before.ts')
	assert.equal(result.files[4].previousPath, 'source.ts')
})

test('preserves quoted path arguments and rejects unclosed quotes', async () => {
	const calls: string[][] = []
	const pi = patchPi('', calls)
	await createDiffSnapshotLoader(
		pi,
		{cwd: root} as Context,
		'-w -- "src/file name.ts"',
	)()
	assert.deepEqual(calls.at(-1), [
		'git',
		'diff',
		'--no-color',
		'-w',
		'HEAD',
		'--',
		'src/file name.ts',
	])
	await assert.rejects(
		createDiffSnapshotLoader(pi, {cwd: root} as Context, '"unfinished')(),
		/Unclosed quote/,
	)
	await assert.rejects(
		createDiffSnapshotLoader(pi, {cwd: root} as Context, 'ref')(),
		/requires a git ref/,
	)
})

test('annotation files round-trip and distinguish repositories and sources', async () => {
	const first = snapshot()
	assert.deepEqual(await loadPersistedAnnotations(first), [])
	await savePersistedAnnotations(first, [annotation])
	assert.deepEqual(
		await loadPersistedAnnotations({...first, patch: 'changed'}),
		[annotation],
	)
	assert.deepEqual(
		await loadPersistedAnnotations(snapshot(join(root, 'other'))),
		[],
	)
	const otherSource = {
		...first,
		source: {...first.source, key: 'jj-rev:another'},
	}
	assert.notEqual(annotationStoreKey(otherSource), annotationStoreKey(first))
	assert.deepEqual(await loadPersistedAnnotations(otherSource), [])
	assert.deepEqual(
		(await readdir(dirname(annotationStorePath(first)))).filter((name) =>
			name.endsWith('.tmp'),
		),
		[],
	)
})

test('coerces stored annotations, enforces limits, and warns on corrupt JSON', async () => {
	const value = snapshot()
	const path = annotationStorePath(value)
	await mkdir(dirname(path), {recursive: true})
	await writeFile(
		path,
		JSON.stringify({
			annotations: [
				null,
				{},
				{
					path: ' file.ts ',
					text: ' note ',
					line: -5,
					end: -10,
					side: 'invalid',
					author: 'invalid',
					replies: [{text: ' reply '}, {}],
				},
			],
		}),
	)
	const loaded = await loadPersistedAnnotations(value)
	assert.equal(loaded.length, 1)
	const {path: storedPath, text, start, end, side, author} = loaded[0]
	assert.deepEqual(
		{path: storedPath, text, start, end, side, author},
		{
			path: 'file.ts',
			text: 'note',
			start: 1,
			end: 1,
			side: 'additions',
			author: 'user',
		},
	)
	assert.equal(loaded[0].replies.length, 1)
	await savePersistedAnnotations(
		value,
		Array.from({length: 510}, () => ({
			...annotation,
			text: 'x'.repeat(10_100),
		})),
	)
	const limited = await loadPersistedAnnotations(value)
	assert.equal(limited.length, 500)
	assert.equal(limited[0].text.length, 10_000)
	await writeFile(path, '{broken')
	const warnings: string[] = []
	assert.deepEqual(
		await loadPersistedAnnotations(value, (message) => warnings.push(message)),
		[],
	)
	assert.deepEqual(warnings, [
		`Diff annotation store is corrupt and will be overwritten on the next save: ${path}`,
	])
})

test('reads the existing legacy format only when the current store is absent', async () => {
	const value = snapshot()
	await writeFile(
		process.env.PI_DIFF_ANNOTATIONS_PATH!,
		JSON.stringify({
			version: 1,
			reviews: {[annotationStoreKey(value)]: {annotations: [annotation]}},
		}),
	)
	assert.deepEqual(await loadPersistedAnnotations(value), [annotation])
	await savePersistedAnnotations(value, [])
	assert.deepEqual(await loadPersistedAnnotations(value), [])
})

test('concurrent annotation saves leave a complete JSON file', async () => {
	const value = snapshot()
	await Promise.all([
		savePersistedAnnotations(value, [annotation]),
		savePersistedAnnotations(value, []),
	])
	const loaded = await loadPersistedAnnotations(value)
	assert.ok([0, 1].includes(loaded.length))
	if (loaded.length) assert.deepEqual(loaded, [annotation])
	assert.equal(
		(await readdir(dirname(annotationStorePath(value)))).some((name) =>
			name.endsWith('.tmp'),
		),
		false,
	)
})

test('preferences clamp widths and survive a filesystem round trip', async () => {
	assert.deepEqual(
		coerceUiPrefs({
			leftSidebarWidth: 1,
			rightSidebarWidth: 900,
			wrapLines: 'true',
		}),
		{leftSidebarWidth: 220, rightSidebarWidth: 720, wrapLines: false},
	)
	assert.deepEqual(await loadUiPrefs(), {
		leftSidebarWidth: 280,
		rightSidebarWidth: 340,
		wrapLines: false,
	})
	const value = await saveUiPrefs({
		leftSidebarWidth: '300.4',
		rightSidebarWidth: 'bad',
		wrapLines: true,
	})
	assert.deepEqual(value, {
		leftSidebarWidth: 300,
		rightSidebarWidth: 340,
		wrapLines: true,
	})
	assert.deepEqual(await loadUiPrefs(), value)
})

test('browser shell includes global and per-file wrapping controls', () => {
	const page = renderHtml('test-token', {
		leftSidebarWidth: 280,
		rightSidebarWidth: 340,
		wrapLines: true,
	})
	assert.match(page, /id="wrapAllButton"/)
	assert.match(page, /id="wrapFileButton"/)
	assert.match(page, /"wrapLines":true/)
	assert.match(page, /overflow: wrapLines \? 'wrap' : 'scroll'/)
})

test('refreshes a real jj working diff while retaining its identity', async () => {
	const path = await repo()
	await writeFile(join(path, 'space name.txt'), 'new\n')
	await writeFile(join(path, 'file.txt'), 'changed\n')
	const refresh = createDiffSnapshotLoader(realPi, {cwd: path} as Context, '--')
	const first = await refresh()
	assert.equal(first.vcs, 'jj')
	assert.deepEqual(first.files.map((file) => file.path).sort(), [
		'file.txt',
		'space name.txt',
	])
	await writeFile(join(path, 'file.txt'), 'another change\n')
	const second = await refresh()
	assert.ok(second.patch.includes('+another change'))
	assert.equal(second.source.key, first.source.key)
	const filtered = await createDiffSnapshotLoader(
		realPi,
		{cwd: path} as Context,
		'-- "space name.txt"',
	)()
	assert.deepEqual(
		filtered.files.map((file) => file.path),
		['space name.txt'],
	)
})

test('loads a real Git working diff after jj creates the fixture history', async () => {
	const path = await repo()
	await rename(join(path, '.jj'), join(root, 'jj-metadata'))
	await writeFile(join(path, 'file.txt'), 'git change\n')
	const result = await createDiffSnapshotLoader(
		realPi,
		{cwd: path} as Context,
		'--',
	)()
	assert.equal(result.vcs, 'git')
	assert.deepEqual(result.files, [
		{path: 'file.txt', previousPath: undefined, status: 'modified'},
	])
	assert.ok(result.patch.includes('+git change'))
})

test('recognizes widened markers without treating plain separators as conflicts', async () => {
	await writeFile(join(root, 'file.txt'), '')
	for (const width of [7, 11]) {
		for (const separator of [
			'='.repeat(width),
			'%'.repeat(width) + ' diff from base',
			'+'.repeat(width) + ' side',
		]) {
			const contents = [
				'<'.repeat(width) + ' conflict',
				'left',
				separator,
				'right',
				'>'.repeat(width) + ' conflict ends',
			].join('\n')
			const file = await saveConflictFile(
				realPi,
				snapshot(),
				'file.txt',
				contents,
			)
			assert.equal(file.resolved, false)
		}
	}
	const file = await saveConflictFile(
		realPi,
		snapshot(),
		'file.txt',
		'heading\n=======\ntext\n',
	)
	assert.equal(file.resolved, true)
})

test('does not read conflict contents through an outside symlink', async () => {
	const path = join(root, 'repo')
	await mkdir(path)
	await writeFile(join(root, 'outside.txt'), 'outside contents')
	await symlink(join(root, 'outside.txt'), join(path, 'linked.txt'))
	const pi = {
		exec: async (_command: string, _args: string[]) => ({
			stdout: 'linked.txt\0',
			stderr: '',
			code: 0,
			killed: false,
		}),
	} as Pi
	assert.deepEqual(await loadConflictFiles(pi, snapshot(path)), [])
})

test('does not write outside the repository through a symlink', async () => {
	const path = await repo()
	const outside = join(root, 'outside.txt')
	await writeFile(outside, 'unchanged')
	await symlink(outside, join(path, 'linked.txt'))
	let rejected = false
	try {
		await saveConflictFile(realPi, snapshot(path), 'linked.txt', 'changed')
	} catch {
		rejected = true
	}
	assert.equal(await readFile(outside, 'utf8'), 'unchanged')
	assert.equal(rejected, true)
})

test('checks symlinked directories and allows in-repo targets and aliased roots', async () => {
	const path = await repo()
	const outside = join(root, 'outside')
	await mkdir(outside)
	await writeFile(join(outside, 'file.txt'), 'unchanged')
	await symlink(outside, join(path, 'outside-link'))
	await assert.rejects(
		saveConflictFile(
			realPi,
			snapshot(path),
			'outside-link/file.txt',
			'changed',
		),
		/escapes repository/,
	)
	assert.equal(await readFile(join(outside, 'file.txt'), 'utf8'), 'unchanged')
	await symlink(join(path, 'file.txt'), join(path, 'inside-link'))
	await saveConflictFile(realPi, snapshot(path), 'inside-link', 'inside\n')
	assert.equal(await readFile(join(path, 'file.txt'), 'utf8'), 'inside\n')
	await symlink(path, join(root, 'repo-alias'))
	await saveConflictFile(
		realPi,
		snapshot(join(root, 'repo-alias')),
		'file.txt',
		'alias\n',
	)
	assert.equal(await readFile(join(path, 'file.txt'), 'utf8'), 'alias\n')
	await writeFile(join(path, '..notes'), 'notes')
	await saveConflictFile(realPi, snapshot(path), '..notes', 'updated notes')
	assert.equal(await readFile(join(path, '..notes'), 'utf8'), 'updated notes')
})

for (const style of ['diff', 'snapshot', 'git']) {
	test(`recognizes and resolves real jj merge conflicts with ${style} markers`, async () => {
		const filename = 'file with\twhitespace\n.txt'
		const path = await repo(filename)
		jj(path, 'config', 'set', '--repo', 'ui.conflict-marker-style', style)
		assert.deepEqual(await loadConflictFiles(realPi, snapshot(path)), [])
		await writeFile(join(path, filename), 'left\n')
		jj(path, 'describe', '-m', 'left')
		const left = jj(path, 'log', '-r', '@', '--no-graph', '-T', 'change_id')
		jj(path, 'new', 'main')
		await writeFile(join(path, filename), 'right\n')
		jj(path, 'describe', '-m', 'right')
		const right = jj(path, 'log', '-r', '@', '--no-graph', '-T', 'change_id')
		jj(path, 'new', left, right)
		assert.equal(jj(path, 'diff', '--types'), '')
		const files = await loadConflictFiles(realPi, snapshot(path))
		assert.equal(files.length, 1)
		assert.equal(files[0].path, filename)
		assert.equal(files[0].resolved, false)
		const unresolved = await saveConflictFile(
			realPi,
			snapshot(path),
			filename,
			files[0].contents,
		)
		assert.equal(unresolved.resolved, false)
		const resolved = await saveConflictFile(
			realPi,
			snapshot(path),
			filename,
			'resolved\n',
		)
		assert.equal(resolved.resolved, true)
		assert.deepEqual(await loadConflictFiles(realPi, snapshot(path)), [])
	})
}

test('rejects absolute and parent-traversal conflict writes', async () => {
	const path = await repo()
	const outside = join(root, 'outside.txt')
	await writeFile(outside, 'unchanged')
	for (const invalid of [
		outside,
		'../outside.txt',
		'dir/../../outside.txt',
		'.',
	]) {
		await assert.rejects(
			saveConflictFile(realPi, snapshot(path), invalid, 'changed'),
		)
	}
	assert.equal(await readFile(outside, 'utf8'), 'unchanged')
	const resolved = await saveConflictFile(
		realPi,
		snapshot(path),
		'file.txt',
		'resolved\n',
	)
	assert.equal(resolved.resolved, true)
	assert.equal(await readFile(join(path, 'file.txt'), 'utf8'), 'resolved\n')
})
