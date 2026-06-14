import {readFile, writeFile} from 'node:fs/promises'
import {isAbsolute, relative, resolve} from 'node:path'
import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'

export type VcsKind = 'jj' | 'git'
export type DiffStatus =
	| 'added'
	| 'modified'
	| 'deleted'
	| 'renamed'
	| 'copied'
	| 'unknown'
export type DiffSourceKind = 'working' | 'pr' | 'ref'

type ExecResult = Awaited<ReturnType<ExtensionAPI['exec']>>

export interface DiffFile {
	path: string
	previousPath?: string
	status: DiffStatus
}

export interface DiffSource {
	kind: DiffSourceKind
	key: string
	label: string
	ref?: string
	url?: string
	headOid?: string
	baseOid?: string
}

export interface DiffSnapshot {
	vcs: VcsKind
	repoRoot: string
	cwd: string
	command: string
	patch: string
	files: DiffFile[]
	source: DiffSource
}

export interface ConflictFile {
	path: string
	contents: string
	resolved: boolean
}

interface ParsedDiffArgs {
	all: string[]
	targetTokens: string[]
	pathspecAfterSeparator: string[]
	hasSeparator: boolean
}

interface DiffRequest {
	kind: 'working' | 'pr' | 'ref' | 'jj-rev'
	args: string[]
	target?: string
	ref?: string
	pathspec: string[]
}

interface PullRequestMetadata {
	number?: number
	url?: string
	headRefOid?: string
	baseRefOid?: string
	headRefName?: string
	baseRefName?: string
}

const formatCommand = (command: string, args: string[]): string =>
	[
		command,
		...args.map((arg) => (/[\s"']/.test(arg) ? JSON.stringify(arg) : arg)),
	].join(' ')

const parseCommandArgs = (value: string): string[] => {
	const args: string[] = []
	let current = ''
	let quote: '"' | "'" | null = null
	let escaping = false

	const push = () => {
		if (current.length > 0) {
			args.push(current)
			current = ''
		}
	}

	for (const char of value) {
		if (escaping) {
			current += char
			escaping = false
			continue
		}

		if (char === '\\' && quote !== "'") {
			escaping = true
			continue
		}

		if (quote) {
			if (char === quote) {
				quote = null
			} else {
				current += char
			}
			continue
		}

		if (char === '"' || char === "'") {
			quote = char
			continue
		}

		if (/\s/.test(char)) {
			push()
			continue
		}

		current += char
	}

	if (escaping) {
		current += '\\'
	}

	if (quote) {
		throw new Error('Unclosed quote in /diff arguments')
	}

	push()
	return args
}

const splitDiffArgs = (args: string[]): ParsedDiffArgs => {
	const separatorIndex = args.indexOf('--')
	if (separatorIndex === -1) {
		return {
			all: args,
			targetTokens: args,
			pathspecAfterSeparator: [],
			hasSeparator: false,
		}
	}
	return {
		all: args,
		targetTokens: args.slice(0, separatorIndex),
		pathspecAfterSeparator: args.slice(separatorIndex + 1),
		hasSeparator: true,
	}
}

export const execOrNull = async (
	pi: ExtensionAPI,
	command: string,
	args: string[],
	cwd: string,
): Promise<ExecResult | null> => {
	try {
		return await pi.exec(command, args, {cwd, timeout: 30_000})
	} catch {
		return null
	}
}

const getJjRoot = async (
	pi: ExtensionAPI,
	cwd: string,
): Promise<string | null> => {
	const result = await execOrNull(pi, 'jj', ['root'], cwd)
	if (!result || result.code !== 0) {
		return null
	}
	const root = result.stdout.trim()
	return root || null
}

const getGitRoot = async (
	pi: ExtensionAPI,
	cwd: string,
): Promise<string | null> => {
	const result = await execOrNull(
		pi,
		'git',
		['rev-parse', '--show-toplevel'],
		cwd,
	)
	if (!result || result.code !== 0) {
		return null
	}
	const root = result.stdout.trim()
	return root || null
}

const assertSuccessfulDiff = (
	result: ExecResult | null,
	command: string,
): ExecResult => {
	if (!result) {
		throw new Error(`Failed to run ${command}`)
	}
	if (result.code !== 0) {
		const message =
			result.stderr.trim() ||
			result.stdout.trim() ||
			`Command failed: ${command}`
		throw new Error(message)
	}
	return result
}

const unquoteGitPath = (value: string): string => {
	let pathValue = value.trim()
	if (pathValue.startsWith('"') && pathValue.endsWith('"')) {
		try {
			pathValue = JSON.parse(pathValue)
		} catch {
			pathValue = pathValue.slice(1, -1)
		}
	}
	return pathValue.replace(/^[ab]\//, '')
}

const parseDiffGitLine = (
	line: string,
): {oldPath: string; newPath: string} | null => {
	const quoted = line.match(/^diff --git ("a\/.+?") ("b\/.+?")$/)
	if (quoted) {
		return {
			oldPath: unquoteGitPath(quoted[1]),
			newPath: unquoteGitPath(quoted[2]),
		}
	}

	const plain = line.match(/^diff --git a\/(.+) b\/(.+)$/)
	if (!plain) {
		return null
	}

	return {oldPath: plain[1], newPath: plain[2]}
}

const parsePatchFileList = (patch: string): DiffFile[] => {
	const files: DiffFile[] = []
	let current: {
		oldPath: string
		newPath: string
		renameFrom?: string
		renameTo?: string
		newFile: boolean
		deletedFile: boolean
		copiedFile: boolean
	} | null = null

	const finish = () => {
		if (!current) {
			return
		}

		let status: DiffStatus = 'modified'
		let filePath = current.newPath
		let previousPath: string | undefined

		if (current.newFile) {
			status = 'added'
		} else if (current.deletedFile) {
			status = 'deleted'
			filePath = current.oldPath
		} else if (current.copiedFile) {
			status = 'copied'
			previousPath = current.renameFrom ?? current.oldPath
			filePath = current.renameTo ?? current.newPath
		} else if (
			current.renameTo ||
			current.renameFrom ||
			current.oldPath !== current.newPath
		) {
			status = 'renamed'
			previousPath = current.renameFrom ?? current.oldPath
			filePath = current.renameTo ?? current.newPath
		}

		files.push({path: filePath, previousPath, status})
		current = null
	}

	for (const line of patch.split('\n')) {
		const header = parseDiffGitLine(line)
		if (header) {
			finish()
			current = {
				oldPath: header.oldPath,
				newPath: header.newPath,
				newFile: false,
				deletedFile: false,
				copiedFile: false,
			}
			continue
		}

		if (!current) {
			continue
		}

		if (line.startsWith('new file mode')) {
			current.newFile = true
		} else if (line.startsWith('deleted file mode')) {
			current.deletedFile = true
		} else if (line.startsWith('copy from ')) {
			current.copiedFile = true
			current.renameFrom = line.slice('copy from '.length)
		} else if (line.startsWith('copy to ')) {
			current.copiedFile = true
			current.renameTo = line.slice('copy to '.length)
		} else if (line.startsWith('rename from ')) {
			current.renameFrom = line.slice('rename from '.length)
		} else if (line.startsWith('rename to ')) {
			current.renameTo = line.slice('rename to '.length)
		} else if (line === '--- /dev/null') {
			current.newFile = true
		} else if (line === '+++ /dev/null') {
			current.deletedFile = true
		}
	}

	finish()
	return files
}

const normalizePrTarget = (value: string): string => {
	const trimmed = value.trim()
	const hashMatch = trimmed.match(/^#(\d+)$/)
	if (hashMatch) return hashMatch[1]
	const pullPathMatch = trimmed.match(/^pull\/(\d+)$/)
	if (pullPathMatch) return pullPathMatch[1]
	return trimmed
}

const isPrCommand = (value: string): boolean =>
	['pr', 'pull', 'pull-request', 'pullrequest'].includes(value.toLowerCase())

const isRefCommand = (value: string): boolean =>
	['ref', 'commit', 'show'].includes(value.toLowerCase())

const isJjRevisionCommand = (value: string): boolean =>
	['jj', 'rev', 'revision', 'revset'].includes(value.toLowerCase())

const isGithubPullUrl = (value: string): boolean =>
	/^https?:\/\/[^/]+\/[^/]+\/[^/]+\/pull\/\d+(?:$|[/?#])/.test(value)

const extractGithubCommitRef = (value: string): string | null => {
	const match = value.match(
		/^https?:\/\/[^/]+\/[^/]+\/[^/]+\/commit\/([0-9a-f]{7,40})(?:$|[/?#])/i,
	)
	return match?.[1] ?? null
}

const isHashPrNumber = (value: string): boolean => /^#\d+$/.test(value)

const isBarePrNumber = (value: string): boolean => /^\d+$/.test(value)

const GIT_RANGE_PATTERN = /(?:^|[^/])\.\.\.?(?:$|[^/])/

const isGitRange = (value: string): boolean => GIT_RANGE_PATTERN.test(value)

const splitGitRange = (
	value: string,
): {left: string; right: string; separator: '..' | '...'} | null => {
	const separator = value.includes('...')
		? '...'
		: value.includes('..')
			? '..'
			: null
	if (!separator) return null
	const [left = '', right = ''] = value.split(separator)
	return {left, right, separator}
}

const resolveGitCommit = async (
	pi: ExtensionAPI,
	gitRoot: string,
	ref: string,
): Promise<string | null> => {
	const result = await execOrNull(
		pi,
		'git',
		['rev-parse', '--verify', `${ref}^{commit}`],
		gitRoot,
	)
	if (!result || result.code !== 0) return null
	return result.stdout.trim().split('\n')[0] || null
}

const resolveJjCommits = async (
	pi: ExtensionAPI,
	jjRoot: string,
	revset: string,
): Promise<string[] | null> => {
	const result = await execOrNull(
		pi,
		'jj',
		['log', '--no-graph', '-r', revset, '-T', 'commit_id ++ "\\n"'],
		jjRoot,
	)
	if (!result || result.code !== 0) return null
	const commits = result.stdout
		.split('\n')
		.map((line) => line.trim())
		.filter(Boolean)
	return commits.length > 0 ? commits : null
}

const canResolveJjRevision = async (
	pi: ExtensionAPI,
	jjRoot: string,
	revset: string,
): Promise<boolean> => (await resolveJjCommits(pi, jjRoot, revset)) !== null

const getPullRequestMetadata = async (
	pi: ExtensionAPI,
	cwd: string,
	target?: string,
): Promise<PullRequestMetadata | null> => {
	const args = ['pr', 'view']
	if (target) args.push(target)
	args.push(
		'--json',
		'number,url,headRefOid,baseRefOid,headRefName,baseRefName',
	)
	const result = await execOrNull(pi, 'gh', args, cwd)
	if (!result || result.code !== 0) return null
	try {
		return JSON.parse(result.stdout) as PullRequestMetadata
	} catch {
		return null
	}
}

const canResolvePullRequest = async (
	pi: ExtensionAPI,
	cwd: string,
	target: string,
): Promise<boolean> => {
	const metadata = await getPullRequestMetadata(pi, cwd, target)
	return metadata !== null
}

const resolveDiffRequest = async (
	pi: ExtensionAPI,
	cwd: string,
	jjRoot: string | null,
	gitRoot: string | null,
	args: string,
): Promise<DiffRequest> => {
	const parsedArgs = splitDiffArgs(parseCommandArgs(args.trim()))
	const first = parsedArgs.targetTokens[0]
	if (!first) {
		return {kind: 'working', args: parsedArgs.all, pathspec: []}
	}

	if (isPrCommand(first)) {
		const rawTarget = parsedArgs.targetTokens[1]
		const pathspec = [
			...parsedArgs.targetTokens.slice(rawTarget ? 2 : 1),
			...parsedArgs.pathspecAfterSeparator,
		]
		return {
			kind: 'pr',
			args: parsedArgs.all,
			target: rawTarget ? normalizePrTarget(rawTarget) : undefined,
			pathspec,
		}
	}

	if (isRefCommand(first)) {
		const ref = parsedArgs.targetTokens[1]
		if (!ref) throw new Error(`/diff ${first} requires a git ref`)
		return {
			kind: 'ref',
			args: parsedArgs.all,
			ref,
			pathspec: [
				...parsedArgs.targetTokens.slice(2),
				...parsedArgs.pathspecAfterSeparator,
			],
		}
	}

	if (isJjRevisionCommand(first)) {
		const ref = parsedArgs.targetTokens[1]
		if (!ref) throw new Error(`/diff ${first} requires a Jujutsu revision`)
		return {
			kind: 'jj-rev',
			args: parsedArgs.all,
			ref,
			pathspec: [
				...parsedArgs.targetTokens.slice(2),
				...parsedArgs.pathspecAfterSeparator,
			],
		}
	}

	if (isGithubPullUrl(first) || isHashPrNumber(first)) {
		return {
			kind: 'pr',
			args: parsedArgs.all,
			target: normalizePrTarget(first),
			pathspec: [
				...parsedArgs.targetTokens.slice(1),
				...parsedArgs.pathspecAfterSeparator,
			],
		}
	}

	const githubCommitRef = extractGithubCommitRef(first)
	if (githubCommitRef) {
		return {
			kind: 'ref',
			args: parsedArgs.all,
			ref: githubCommitRef,
			pathspec: [
				...parsedArgs.targetTokens.slice(1),
				...parsedArgs.pathspecAfterSeparator,
			],
		}
	}

	if (first.startsWith('-')) {
		return {kind: 'working', args: parsedArgs.all, pathspec: []}
	}

	const pathspec = [
		...parsedArgs.targetTokens.slice(1),
		...parsedArgs.pathspecAfterSeparator,
	]
	if (
		jjRoot &&
		!isGitRange(first) &&
		(await canResolveJjRevision(pi, jjRoot, first))
	) {
		return {kind: 'jj-rev', args: parsedArgs.all, ref: first, pathspec}
	}

	if (isGitRange(first)) {
		return {kind: 'ref', args: parsedArgs.all, ref: first, pathspec}
	}

	if (gitRoot && (await resolveGitCommit(pi, gitRoot, first))) {
		return {kind: 'ref', args: parsedArgs.all, ref: first, pathspec}
	}

	if (isBarePrNumber(first) && (await canResolvePullRequest(pi, cwd, first))) {
		return {
			kind: 'pr',
			args: parsedArgs.all,
			target: first,
			pathspec,
		}
	}

	return {kind: 'working', args: parsedArgs.all, pathspec: []}
}

const sourceForWorking = (vcs: VcsKind, command: string): DiffSource => ({
	kind: 'working',
	key: `working:${vcs}:${command}`,
	label: 'Working diff',
})

const sourceForGitRef = async (
	pi: ExtensionAPI,
	gitRoot: string,
	ref: string,
): Promise<DiffSource> => {
	if (isGitRange(ref)) {
		const range = splitGitRange(ref)
		const left = range?.left
			? await resolveGitCommit(pi, gitRoot, range.left)
			: null
		const right = range?.right
			? await resolveGitCommit(pi, gitRoot, range.right)
			: null
		return {
			kind: 'ref',
			key: `git-range:${ref}:${left ?? ''}:${right ?? ''}`,
			label: `Git range ${ref}`,
			ref,
			headOid: right ?? undefined,
			baseOid: left ?? undefined,
		}
	}

	const resolved = await resolveGitCommit(pi, gitRoot, ref)
	return {
		kind: 'ref',
		key: `git-commit:${resolved ?? ref}`,
		label: resolved
			? `Git ref ${ref} (${resolved.slice(0, 12)})`
			: `Git ref ${ref}`,
		ref,
		headOid: resolved ?? undefined,
	}
}

const loadPullRequestSnapshot = async (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	request: DiffRequest,
	repoRoot: string,
): Promise<DiffSnapshot> => {
	if (request.pathspec.length > 0) {
		throw new Error('Path filters are not supported for PR diffs yet')
	}
	const metadata = await getPullRequestMetadata(pi, repoRoot, request.target)
	const ghArgs = ['pr', 'diff']
	if (request.target) ghArgs.push(request.target)
	ghArgs.push('--patch', '--color', 'never')
	const result = assertSuccessfulDiff(
		await execOrNull(pi, 'gh', ghArgs, repoRoot),
		formatCommand('gh', ghArgs),
	)
	const identity = metadata?.url ?? request.target ?? 'current-branch'
	const head = metadata?.headRefOid
	const numberLabel = metadata?.number ? `#${metadata.number}` : request.target
	const branchLabel = metadata?.headRefName
		? ` ${metadata.baseRefName ?? 'base'}…${metadata.headRefName}`
		: ''
	return {
		vcs: 'git',
		repoRoot,
		cwd: ctx.cwd,
		command: formatCommand('gh', ghArgs),
		patch: result.stdout,
		files: parsePatchFileList(result.stdout),
		source: {
			kind: 'pr',
			key: `github-pr:${identity}${head ? `@${head}` : ''}`,
			label: `PR ${numberLabel ?? 'current branch'}${branchLabel}`,
			url: metadata?.url,
			headOid: metadata?.headRefOid,
			baseOid: metadata?.baseRefOid,
		},
	}
}

const loadGitRefSnapshot = async (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	request: DiffRequest,
	gitRoot: string,
): Promise<DiffSnapshot> => {
	const ref = request.ref
	if (!ref) throw new Error('Missing git ref')
	const gitArgs = isGitRange(ref)
		? ['diff', '--no-color', '--find-renames', ref]
		: ['show', '--format=', '--patch', '--no-color', '--find-renames', ref]
	if (request.pathspec.length > 0) gitArgs.push('--', ...request.pathspec)
	const result = assertSuccessfulDiff(
		await execOrNull(pi, 'git', gitArgs, gitRoot),
		formatCommand('git', gitArgs),
	)
	return {
		vcs: 'git',
		repoRoot: gitRoot,
		cwd: ctx.cwd,
		command: formatCommand('git', gitArgs),
		patch: result.stdout,
		files: parsePatchFileList(result.stdout),
		source: await sourceForGitRef(pi, gitRoot, ref),
	}
}

const sourceForJjRevision = async (
	pi: ExtensionAPI,
	jjRoot: string,
	revset: string,
): Promise<DiffSource> => {
	const commits = await resolveJjCommits(pi, jjRoot, revset)
	const commitKey = commits?.join(',') ?? revset
	const shortCommits = commits?.map((commit) => commit.slice(0, 12)).join(', ')
	return {
		kind: 'ref',
		key: `jj-rev:${commitKey}`,
		label: shortCommits
			? `Jujutsu revision ${revset} (${shortCommits})`
			: `Jujutsu revision ${revset}`,
		ref: revset,
		headOid: commits?.[0],
	}
}

const loadJjRevisionSnapshot = async (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	request: DiffRequest,
	jjRoot: string,
): Promise<DiffSnapshot> => {
	const ref = request.ref
	if (!ref) throw new Error('Missing Jujutsu revision')
	const jjArgs = ['--color', 'never', 'diff', '--git', '-r', ref]
	if (request.pathspec.length > 0) jjArgs.push('--', ...request.pathspec)
	const result = assertSuccessfulDiff(
		await execOrNull(pi, 'jj', jjArgs, jjRoot),
		formatCommand('jj', jjArgs),
	)
	return {
		vcs: 'jj',
		repoRoot: jjRoot,
		cwd: ctx.cwd,
		command: formatCommand('jj', jjArgs),
		patch: result.stdout,
		files: parsePatchFileList(result.stdout),
		source: await sourceForJjRevision(pi, jjRoot, ref),
	}
}

const hasConflictMarkers = (contents: string): boolean =>
	/^<<<<<<<(?: |$)/m.test(contents) &&
	/^=======$/m.test(contents) &&
	/^>>>>>>>(?: |$)/m.test(contents)

const safeRepoFilePath = (repoRoot: string, filePath: string): string => {
	if (isAbsolute(filePath)) {
		throw new Error('Conflict path must be repository-relative')
	}
	const absolutePath = resolve(repoRoot, filePath)
	const relativePath = relative(repoRoot, absolutePath)
	if (
		relativePath === '' ||
		relativePath.startsWith('..') ||
		isAbsolute(relativePath)
	) {
		throw new Error(`Conflict path escapes repository: ${filePath}`)
	}
	return absolutePath
}

const uniquePaths = (paths: string[]): string[] =>
	Array.from(new Set(paths.map((path) => path.trim()).filter(Boolean)))

const getGitConflictPaths = async (
	pi: ExtensionAPI,
	repoRoot: string,
): Promise<string[]> => {
	const result = await execOrNull(
		pi,
		'git',
		['diff', '--name-only', '--diff-filter=U'],
		repoRoot,
	)
	if (!result || result.code !== 0) return []
	return uniquePaths(result.stdout.split('\n'))
}

const getJjConflictPaths = async (
	pi: ExtensionAPI,
	repoRoot: string,
): Promise<string[]> => {
	const result = await execOrNull(pi, 'jj', ['diff', '--types'], repoRoot)
	if (!result || result.code !== 0) return []
	return uniquePaths(
		result.stdout.split('\n').map((line) => {
			const match = line.match(/^([A-Z-]{2})\s+(.+)$/)
			return match?.[1].includes('C') ? match[2] : ''
		}),
	)
}

export const loadConflictFiles = async (
	pi: ExtensionAPI,
	snapshot: DiffSnapshot,
): Promise<ConflictFile[]> => {
	const paths =
		snapshot.vcs === 'jj'
			? await getJjConflictPaths(pi, snapshot.repoRoot)
			: await getGitConflictPaths(pi, snapshot.repoRoot)
	const files: ConflictFile[] = []
	for (const path of paths) {
		try {
			const contents = await readFile(
				safeRepoFilePath(snapshot.repoRoot, path),
				'utf8',
			)
			files.push({path, contents, resolved: !hasConflictMarkers(contents)})
		} catch {}
	}
	return files
}

export const saveConflictFile = async (
	pi: ExtensionAPI,
	snapshot: DiffSnapshot,
	path: string,
	contents: string,
): Promise<ConflictFile> => {
	const resolved = !hasConflictMarkers(contents)
	await writeFile(safeRepoFilePath(snapshot.repoRoot, path), contents, 'utf8')
	if (resolved && snapshot.vcs === 'git') {
		const result = await execOrNull(
			pi,
			'git',
			['add', '--', path],
			snapshot.repoRoot,
		)
		if (!result || result.code !== 0) {
			const message =
				result?.stderr.trim() ||
				result?.stdout.trim() ||
				'Failed to mark file resolved'
			throw new Error(message)
		}
	}
	return {path, contents, resolved}
}

export const createDiffSnapshotLoader = (
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	args: string,
) => {
	// Roots and request kind are deterministic for fixed args, so resolve them
	// once and reuse across refreshes instead of re-running jj/git/gh detection
	// (including a `gh pr view` network call for auto-detected PRs) every time.
	let resolution: {
		jjRoot: string | null
		gitRoot: string | null
		request: DiffRequest
	} | null = null
	const resolve = async () => {
		if (resolution) return resolution
		const jjRoot = await getJjRoot(pi, ctx.cwd)
		const gitRoot = await getGitRoot(pi, ctx.cwd)
		const request = await resolveDiffRequest(pi, ctx.cwd, jjRoot, gitRoot, args)
		resolution = {jjRoot, gitRoot, request}
		return resolution
	}

	return async (): Promise<DiffSnapshot> => {
		const {jjRoot, gitRoot, request} = await resolve()

		if (request.kind === 'pr') {
			return loadPullRequestSnapshot(
				pi,
				ctx,
				request,
				gitRoot ?? jjRoot ?? ctx.cwd,
			)
		}

		if (request.kind === 'ref') {
			if (!gitRoot) {
				throw new Error('/diff ref requires a Git repository')
			}
			return loadGitRefSnapshot(pi, ctx, request, gitRoot)
		}

		if (request.kind === 'jj-rev') {
			if (!jjRoot) {
				throw new Error('/diff jj requires a Jujutsu repository')
			}
			return loadJjRevisionSnapshot(pi, ctx, request, jjRoot)
		}

		if (jjRoot) {
			const jjArgs = ['--color', 'never', 'diff', '--git', ...request.args]
			const result = assertSuccessfulDiff(
				await execOrNull(pi, 'jj', jjArgs, ctx.cwd),
				formatCommand('jj', jjArgs),
			)
			return {
				vcs: 'jj',
				repoRoot: jjRoot,
				cwd: ctx.cwd,
				command: formatCommand('jj', jjArgs),
				patch: result.stdout,
				files: parsePatchFileList(result.stdout),
				source: sourceForWorking('jj', formatCommand('jj', jjArgs)),
			}
		}

		if (!gitRoot) {
			throw new Error('/diff requires a Jujutsu or Git repository')
		}

		const hasHead = await execOrNull(
			pi,
			'git',
			['rev-parse', '--verify', 'HEAD'],
			gitRoot,
		)
		const gitArgs =
			hasHead?.code === 0
				? ['diff', '--no-color', 'HEAD', '--', ...request.args]
				: ['diff', '--no-color', '--', ...request.args]
		const result = assertSuccessfulDiff(
			await execOrNull(pi, 'git', gitArgs, gitRoot),
			formatCommand('git', gitArgs),
		)

		return {
			vcs: 'git',
			repoRoot: gitRoot,
			cwd: ctx.cwd,
			command: formatCommand('git', gitArgs),
			patch: result.stdout,
			files: parsePatchFileList(result.stdout),
			source: sourceForWorking('git', formatCommand('git', gitArgs)),
		}
	}
}
