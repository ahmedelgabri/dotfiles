import {createHash} from 'node:crypto'
import {mkdir, readFile, rename, writeFile} from 'node:fs/promises'
import {homedir} from 'node:os'
import {dirname, join} from 'node:path'
import type {DiffSnapshot} from './vcs.js'

export type StoredAnnotationAuthor = 'user' | 'pi'

export interface StoredReviewReply {
	id: string
	author: StoredAnnotationAuthor
	text: string
	createdAt: string
}

export interface StoredReviewAnnotation {
	id: string
	path: string
	side: 'additions' | 'deletions'
	start: number
	end: number
	endSide: 'additions' | 'deletions'
	text: string
	author: StoredAnnotationAuthor
	createdAt: string
	replies: StoredReviewReply[]
}

interface StoredReview {
	version: 1
	key: string
	repoRoot: string
	sourceKey: string
	sourceKind: string
	sourceLabel: string
	sourceRef?: string
	sourceUrl?: string
	command: string
	updatedAt: string
	annotations: StoredReviewAnnotation[]
}

interface LegacyStoreFile {
	version: 1
	reviews: Record<string, Omit<StoredReview, 'version'>>
}

const MAX_ANNOTATIONS_PER_REVIEW = 500
const MAX_REPLIES_PER_ANNOTATION = 500

const getPiAgentDir = (): string =>
	process.env.PI_CODING_AGENT_DIR?.trim() || join(homedir(), '.pi', 'agent')

const getStoreDir = (): string =>
	process.env.PI_DIFF_ANNOTATIONS_DIR?.trim() || join(getPiAgentDir(), 'diff')

const getLegacyStorePath = (): string =>
	process.env.PI_DIFF_ANNOTATIONS_PATH?.trim() ||
	join(getPiAgentDir(), 'diff-annotations.json')

const hashValue = (value: string): string =>
	createHash('sha256').update(value).digest('hex')

const shortHash = (value: string, length = 12): string =>
	hashValue(value).slice(0, length)

export const annotationStoreKey = (snapshot: DiffSnapshot): string =>
	hashValue(`${snapshot.repoRoot}\n${snapshot.source.key}`)

const sanitizeSegment = (
	value: string,
	fallback: string,
	maxLength = 96,
): string => {
	const sanitized = value
		.normalize('NFKD')
		.replace(/[\u0300-\u036f]/g, '')
		.replace(/[^A-Za-z0-9._-]+/g, '-')
		.replace(/-+/g, '-')
		.replace(/^[-.]+|[-.]+$/g, '')
		.slice(0, maxLength)
		.replace(/^[-.]+|[-.]+$/g, '')
	return sanitized || fallback
}

const sanitizeRootPath = (value: string): string => {
	const sanitized = value
		.normalize('NFKD')
		.replace(/[\u0300-\u036f]/g, '')
		.replace(/[\/\\<>:"|?*\x00-\x1F]+/g, '_')
		.replace(/_+/g, '_')
		.slice(0, 240)
		.replace(/^_+|_+$/g, '')
	return sanitized || 'repo'
}

const repoSegment = (snapshot: DiffSnapshot): string =>
	sanitizeRootPath(snapshot.repoRoot)

const pullRequestNumber = (url: string | undefined): string | null => {
	const match = url?.match(/\/pull\/(\d+)(?:$|[/?#])/)
	return match?.[1] ?? null
}

const sourceHumanName = (snapshot: DiffSnapshot): string => {
	const {source} = snapshot
	const head = source.headOid?.slice(0, 12)
	const base = source.baseOid?.slice(0, 12)
	if (source.kind === 'pr') {
		return [
			'pr',
			pullRequestNumber(source.url) ?? source.ref ?? 'current',
			head,
		]
			.filter(Boolean)
			.join('-')
	}
	if (source.kind === 'working') {
		return 'working'
	}
	if (source.key.startsWith('jj-rev:')) {
		return ['jj', source.ref ?? source.label, head].filter(Boolean).join('-')
	}
	if (source.key.startsWith('git-range:')) {
		return ['git-range', source.ref ?? source.label, base, head]
			.filter(Boolean)
			.join('-')
	}
	if (source.headOid) {
		return ['git', source.ref ?? source.label, head].filter(Boolean).join('-')
	}
	return [source.kind, source.ref ?? source.label].filter(Boolean).join('-')
}

const sourceSegment = (snapshot: DiffSnapshot): string =>
	`${sanitizeSegment(sourceHumanName(snapshot), 'diff')}-${shortHash(snapshot.source.key)}`

export const annotationStorePath = (snapshot: DiffSnapshot): string =>
	join(getStoreDir(), repoSegment(snapshot), `${sourceSegment(snapshot)}.json`)

const coerceSide = (value: unknown): 'additions' | 'deletions' =>
	value === 'deletions' ? 'deletions' : 'additions'

const coerceAuthor = (value: unknown): StoredAnnotationAuthor =>
	value === 'pi' ? 'pi' : 'user'

const coerceLine = (value: unknown): number => {
	const numberValue = typeof value === 'number' ? value : Number(value)
	if (!Number.isFinite(numberValue)) return 1
	return Math.max(1, Math.trunc(numberValue))
}

const coerceText = (value: unknown, maxLength: number): string =>
	(typeof value === 'string' ? value : '').slice(0, maxLength)

const coerceId = (
	value: unknown,
	prefix: string,
	fallbackIndex: number,
): string => {
	const text = typeof value === 'string' ? value.trim() : ''
	return text || `${prefix}-persisted-${fallbackIndex}`
}

const coerceReply = (
	value: unknown,
	index: number,
): StoredReviewReply | null => {
	if (!value || typeof value !== 'object') return null
	const record = value as Record<string, unknown>
	const text = coerceText(record.text, 10_000).trim()
	if (!text) return null
	const createdAt =
		typeof record.createdAt === 'string'
			? record.createdAt
			: new Date().toISOString()
	return {
		id: coerceId(record.id, 'r', index),
		author: coerceAuthor(record.author),
		text,
		createdAt,
	}
}

const coerceAnnotation = (
	value: unknown,
	index: number,
): StoredReviewAnnotation | null => {
	if (!value || typeof value !== 'object') return null
	const record = value as Record<string, unknown>
	const path = typeof record.path === 'string' ? record.path.trim() : ''
	const text = coerceText(record.text, 10_000).trim()
	if (!path || !text) return null
	const start = coerceLine(record.start ?? record.line ?? record.lineNumber)
	const end = Math.max(
		start,
		coerceLine(record.end ?? record.endLine ?? record.start ?? record.line),
	)
	const createdAt =
		typeof record.createdAt === 'string'
			? record.createdAt
			: new Date().toISOString()
	const replies = Array.isArray(record.replies)
		? record.replies
				.slice(0, MAX_REPLIES_PER_ANNOTATION)
				.map(coerceReply)
				.filter((reply): reply is StoredReviewReply => Boolean(reply))
		: []
	return {
		id: coerceId(record.id, 'a', index),
		path,
		side: coerceSide(record.side),
		start,
		end,
		endSide: coerceSide(record.endSide ?? record.side),
		text,
		author: coerceAuthor(record.author),
		createdAt,
		replies,
	}
}

const coerceAnnotations = (value: unknown): StoredReviewAnnotation[] => {
	if (!Array.isArray(value)) return []
	return value
		.slice(0, MAX_ANNOTATIONS_PER_REVIEW)
		.map(coerceAnnotation)
		.filter((annotation): annotation is StoredReviewAnnotation =>
			Boolean(annotation),
		)
}

const readReviewFile = async (
	path: string,
): Promise<{
	found: boolean
	corrupt: boolean
	annotations: StoredReviewAnnotation[]
}> => {
	try {
		const raw = await readFile(path, 'utf8')
		const parsed = JSON.parse(raw)
		return {
			found: true,
			corrupt: false,
			annotations: coerceAnnotations(parsed?.annotations),
		}
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
			return {found: false, corrupt: false, annotations: []}
		}
		if (error instanceof SyntaxError) {
			return {found: true, corrupt: true, annotations: []}
		}
		throw error
	}
}

const loadLegacyAnnotations = async (
	snapshot: DiffSnapshot,
): Promise<StoredReviewAnnotation[]> => {
	try {
		const raw = await readFile(getLegacyStorePath(), 'utf8')
		const parsed = JSON.parse(raw) as LegacyStoreFile
		if (!parsed || parsed.version !== 1 || !parsed.reviews) return []
		return coerceAnnotations(
			parsed.reviews[annotationStoreKey(snapshot)]?.annotations,
		)
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === 'ENOENT') return []
		if (error instanceof SyntaxError) return []
		throw error
	}
}

export const loadPersistedAnnotations = async (
	snapshot: DiffSnapshot,
	onWarning?: (message: string) => void,
): Promise<StoredReviewAnnotation[]> => {
	const path = annotationStorePath(snapshot)
	const review = await readReviewFile(path)
	if (review.corrupt) {
		onWarning?.(
			`Diff annotation store is corrupt and will be overwritten on the next save: ${path}`,
		)
	}
	if (review.found) return review.annotations
	return loadLegacyAnnotations(snapshot)
}

export const savePersistedAnnotations = async (
	snapshot: DiffSnapshot,
	annotations: StoredReviewAnnotation[],
): Promise<void> => {
	const path = annotationStorePath(snapshot)
	const review: StoredReview = {
		version: 1,
		key: annotationStoreKey(snapshot),
		repoRoot: snapshot.repoRoot,
		sourceKey: snapshot.source.key,
		sourceKind: snapshot.source.kind,
		sourceLabel: snapshot.source.label,
		sourceRef: snapshot.source.ref,
		sourceUrl: snapshot.source.url,
		command: snapshot.command,
		updatedAt: new Date().toISOString(),
		annotations: coerceAnnotations(annotations),
	}
	await mkdir(dirname(path), {recursive: true})
	const tmpPath = `${path}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`
	await writeFile(tmpPath, JSON.stringify(review, null, 2) + '\n', 'utf8')
	await rename(tmpPath, path)
}
