import {html, render} from 'htm/preact'
import {useCallback, useEffect, useMemo, useRef, useState} from 'preact/hooks'
import {Marked} from 'marked'
import DOMPurify from 'dompurify'
import * as diffsLib from '@pierre/diffs'
import * as treesLib from '@pierre/trees'

const marked = new Marked({gfm: true, breaks: true, async: false})

const renderMarkdown = (value) => {
	const text = typeof value === 'string' ? value : ''
	if (!text) return {__html: ''}
	const html = marked.parse(text)
	return {__html: DOMPurify.sanitize(html)}
}

const hasConflictMarkers = (contents) =>
	/^<<<<<<<(?: |$)/m.test(contents) &&
	/^=======$/m.test(contents) &&
	/^>>>>>>>(?: |$)/m.test(contents)

const resolveMergeConflict =
	diffsLib.resolveMergeConflict || diffsLib.resolveConflict

const config = window.PI_DIFF_CONFIG

const LEFT_SIDEBAR_WIDTH_KEY = 'pi.diff.leftSidebarWidth'
const RIGHT_SIDEBAR_WIDTH_KEY = 'pi.diff.rightSidebarWidth'
const MIN_SIDEBAR_WIDTH = 220
const MAX_SIDEBAR_WIDTH = 720

const clamp = (value, min, max) => Math.max(min, Math.min(max, value))

const readNumberPreference = (key, fallback) => {
	try {
		const value = Number(window.localStorage.getItem(key))
		return Number.isFinite(value)
			? clamp(value, MIN_SIDEBAR_WIDTH, MAX_SIDEBAR_WIDTH)
			: fallback
	} catch {
		return fallback
	}
}

const writeNumberPreference = (key, value) => {
	try {
		window.localStorage.setItem(key, String(value))
	} catch {}
}

const apiUrl = (path) =>
	path +
	(path.includes('?') ? '&' : '?') +
	'token=' +
	encodeURIComponent(config.token)

const escapeHtml = (value) =>
	String(value).replace(
		/[&<>"]/g,
		(char) =>
			({
				'&': '&amp;',
				'<': '&lt;',
				'>': '&gt;',
				'"': '&quot;',
			})[char],
	)

const normalizePath = (value) => {
	const text = String(value || '')
	return text.startsWith('a/') || text.startsWith('b/') ? text.slice(2) : text
}

const lineRangeLabel = (annotation) =>
	annotation.start === annotation.end
		? String(annotation.start)
		: annotation.start + '-' + annotation.end

const annotationLocation = (annotation) =>
	annotation.path +
	' · ' +
	annotation.side +
	' · lines ' +
	lineRangeLabel(annotation)

const authorLabel = (author) => (author === 'pi' ? 'pi' : 'you')

const ICONS = {
	diff: '\ueae1',
	layout: '\uebeb',
	split: '\ueb57',
	refresh: '\ueb37',
	send: '\uec0f',
	close: '\uea76',
}

const Icon = ({name}) => html`
	<span class="icon" aria-hidden="true">${ICONS[name] || ''}</span>
`

const api = async (path, options = {}) => {
	const {timeoutMs = 30_000, headers = {}, signal, ...fetchOptions} = options
	const controller = new AbortController()
	const timeout = setTimeout(() => controller.abort(), timeoutMs)

	try {
		const response = await fetch(apiUrl(path), {
			...fetchOptions,
			signal: signal || controller.signal,
			headers: {
				'Content-Type': 'application/json',
				...headers,
			},
		})

		let body = null
		try {
			body = await response.json()
		} catch {
			throw new Error('Invalid JSON from ' + path)
		}

		if (!response.ok) {
			throw new Error(
				body?.error || response.statusText || 'HTTP ' + response.status,
			)
		}

		return body
	} catch (error) {
		if (error?.name === 'AbortError') {
			throw new Error('Timed out waiting for ' + path)
		}
		throw error
	} finally {
		clearTimeout(timeout)
	}
}

const statusFromDiffType = (type) => {
	if (type === 'new') return 'added'
	if (type === 'deleted') return 'deleted'
	if (type === 'rename-pure' || type === 'rename-changed') return 'renamed'
	return 'modified'
}

const treeStatus = (status) => {
	if (
		status === 'added' ||
		status === 'deleted' ||
		status === 'renamed' ||
		status === 'modified'
	)
		return status
	return 'modified'
}

const mergeFileLists = (files, conflicts) => {
	const merged = files.map((file) => ({...file}))
	const seen = new Set(merged.map((file) => file.path))
	for (const conflict of conflicts) {
		if (seen.has(conflict.path)) continue
		seen.add(conflict.path)
		merged.push({path: conflict.path, status: 'modified'})
	}
	return merged
}

const fileTreeUnsafeCss = `
:host {
	--trees-level-gap-override: 4px;
	--trees-item-padding-x-override: 5px;
	--trees-item-row-gap-override: 4px;
	--trees-icon-width-override: 14px;
	--trees-font-size-override: 13px;
}
[data-file-tree-virtualized-scroll='true'] {
	overflow-x: auto;
}
[data-file-tree-virtualized-list='true'],
[data-file-tree-virtualized-sticky='true'] {
	min-width: max-content;
}
[data-type='item'] {
	min-width: calc(100% - var(--trees-scrollbar-gutter));
	width: max-content;
}
[data-item-section='content'] {
	flex: 0 0 auto;
	max-width: none;
	overflow: visible;
}
[data-truncate-group-container='middle'] {
	min-width: max-content;
}
`

const parsePatchWithDiffs = (patch, fallbackFiles) => {
	if (!patch.trim()) return {diffs: [], files: fallbackFiles}

	try {
		const parsed = diffsLib.parsePatchFiles(patch, 'pi-diff-review')
		const diffs = parsed.flatMap((parsedPatch) => parsedPatch.files || [])
		const files = diffs
			.map((fileDiff) => ({
				path: normalizePath(fileDiff.name),
				previousPath: fileDiff.prevName
					? normalizePath(fileDiff.prevName)
					: undefined,
				status: statusFromDiffType(fileDiff.type),
			}))
			.filter((file) => file.path)
		return {diffs, files: files.length > 0 ? files : fallbackFiles}
	} catch (error) {
		console.error(error)
		return {diffs: [], files: fallbackFiles}
	}
}

const closeThisTab = () => {
	window.close()
	setTimeout(() => {
		window.open('', '_self')
		window.close()
	}, 50)
	setTimeout(() => {
		document.body.innerHTML =
			'<div style="font: 16px system-ui, sans-serif; padding: 24px; color: var(--text); background: var(--bg); min-height: 100vh;"><h1 style="font-size: 20px; margin: 0 0 8px;">Diff review server closed</h1><p style="color: var(--muted); margin: 0;">Your browser blocked automatic tab closing. You can close this tab manually.</p></div>'
	}, 350)
}

const setCurrentPathFromFiles = (setCurrentPath, files) => {
	setCurrentPath((current) =>
		current && files.some((file) => file.path === current)
			? current
			: (files[0]?.path ?? null),
	)
}

const Header = ({
	status,
	subtitle,
	layout,
	onToggleLayout,
	onRefresh,
	onSubmit,
	onCancel,
	submitting,
}) => html`
	<header class="header">
		<div>
			<div class="title">
				<${Icon} name="diff" />
				<span>pi diff review</span>
			</div>
			<div class="subtitle">${subtitle}</div>
		</div>
		<div class="actions">
			<span
				id="status"
				class=${'status' + (status.kind ? ' ' + status.kind : '')}
				>${status.message}</span
			>
			<button id="layoutButton" type="button" onClick=${onToggleLayout}>
				<${Icon} name=${layout === 'split' ? 'layout' : 'split'} />
				<span>${layout === 'split' ? 'Unified' : 'Split'}</span>
			</button>
			<button id="refreshButton" type="button" onClick=${onRefresh}>
				<${Icon} name="refresh" />
				<span>Refresh</span>
			</button>
			<button
				class="primary"
				id="sendButton"
				type="button"
				disabled=${submitting}
				onClick=${onSubmit}
			>
				<${Icon} name="send" />
				<span>Send annotations to pi</span>
			</button>
			<button id="cancelButton" type="button" onClick=${onCancel}>
				<${Icon} name="close" />
				<span>Close server</span>
			</button>
		</div>
	</header>
`

const FallbackFileList = ({files, currentPath, onSelect}) => html`
	<ul class="file-list">
		${files.map(
			(file) => html`
				<li key=${file.path}>
					<button
						type="button"
						class=${file.path === currentPath ? 'active' : ''}
						onClick=${() => onSelect(file.path)}
					>
						${file.path}
					</button>
				</li>
			`,
		)}
	</ul>
`

const FileTreePanel = ({files, currentPath, onSelect}) => {
	const treeRef = useRef(null)

	useEffect(() => {
		const host = treeRef.current
		if (!host || files.length === 0) return undefined

		host.innerHTML = ''
		try {
			const paths = files.map((file) => file.path)
			const directories = new Set()
			for (const filePath of paths) {
				const parts = filePath.split('/')
				let prefix = ''
				for (let i = 0; i < parts.length - 1; i += 1) {
					prefix = prefix ? prefix + '/' + parts[i] : parts[i]
					directories.add(prefix)
				}
			}

			const tree = new treesLib.FileTree({
				paths,
				search: true,
				flattenEmptyDirectories: false,
				unsafeCSS: fileTreeUnsafeCss,
				initialExpandedPaths: Array.from(directories).slice(0, 100),
				gitStatus: files.map((file) => ({
					path: file.path,
					status: treeStatus(file.status),
				})),
			})
			tree.render({fileTreeContainer: host})
			const unsubscribe = tree.subscribe(() => {
				const selected = tree.getSelectedPaths()[0] || tree.getFocusedPath()
				if (selected && selected !== currentPath) onSelect(selected)
			})

			if (currentPath) {
				const item = tree.getItem(currentPath)
				if (item) {
					item.select()
					item.focus()
				}
			}

			return () => {
				unsubscribe?.()
				tree.cleanUp()
			}
		} catch (error) {
			console.error(error)
			host.innerHTML = ''
		}
		return undefined
	}, [files, currentPath, onSelect])

	if (files.length === 0) {
		return html`<${FallbackFileList}
			files=${files}
			currentPath=${currentPath}
			onSelect=${onSelect}
		/>`
	}

	return html`<div ref=${treeRef} class="tree-host"></div>`
}

const ReplyEntry = ({reply, onDelete}) => html`
	<div class=${'reply reply-' + reply.author}>
		<div class="reply-header">
			<span class=${'annotation-author ' + reply.author}>
				${authorLabel(reply.author)}
			</span>
			${onDelete
				? html`<button
						type="button"
						class="link danger"
						onClick=${() => onDelete(reply.id)}
					>
						Delete
					</button>`
				: null}
		</div>
		<div
			class="reply-text markdown"
			dangerouslySetInnerHTML=${renderMarkdown(reply.text)}
		></div>
	</div>
`

const ReplyForm = ({onSubmit}) => {
	const [value, setValue] = useState('')
	const submit = () => {
		const text = value.trim()
		if (!text) return
		onSubmit(text)
		setValue('')
	}
	return html`
		<form
			class="reply-form"
			onSubmit=${(event) => {
				event.preventDefault()
				submit()
			}}
		>
			<textarea
				placeholder="Write a reply (Cmd/Ctrl+Enter to send)…"
				value=${value}
				onInput=${(event) => setValue(event.currentTarget.value)}
				onKeyDown=${(event) => {
					if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
						event.preventDefault()
						submit()
					}
				}}
			></textarea>
			<div class="reply-actions">
				<button class="primary" type="submit" disabled=${!value.trim()}>
					Reply
				</button>
			</div>
		</form>
	`
}

const AnnotationCard = ({
	annotation,
	onDelete,
	onJump,
	onAddReply,
	onDeleteReply,
	inline,
}) => html`
	<div
		class=${'annotation-card' +
		(inline ? ' inline' : '') +
		' annotation-by-' +
		annotation.author}
	>
		<div class="annotation-header">
			<span class=${'annotation-author ' + annotation.author}>
				${authorLabel(annotation.author)}
			</span>
			<span class="annotation-meta">${annotationLocation(annotation)}</span>
		</div>
		<div
			class="annotation-text markdown"
			dangerouslySetInnerHTML=${renderMarkdown(annotation.text)}
		></div>
		${annotation.replies.length > 0
			? html`<div class="replies">
					${annotation.replies.map(
						(reply) =>
							html`<${ReplyEntry}
								key=${reply.id}
								reply=${reply}
								onDelete=${onDeleteReply
									? (replyId) => onDeleteReply(annotation.id, replyId)
									: null}
							/>`,
					)}
				</div>`
			: null}
		${onAddReply
			? html`<${ReplyForm}
					onSubmit=${(text) => onAddReply(annotation.id, text)}
				/>`
			: null}
		<div class="annotation-actions">
			${onJump
				? html`<button
						type="button"
						onClick=${() => onJump(annotation.path, annotation)}
					>
						Show file
					</button>`
				: null}
			${onDelete
				? html`<button
						type="button"
						class="danger"
						onClick=${() => onDelete(annotation.id)}
					>
						Delete
					</button>`
				: null}
		</div>
	</div>
`

const DiffViewer = ({
	patch,
	diffs,
	currentPath,
	layout,
	annotations,
	activeRange,
	onAddAnnotation,
	onDeleteAnnotation,
}) => {
	const diffRef = useRef(null)
	const currentDiff = useMemo(() => {
		if (!currentPath) return null
		return (
			diffs.find(
				(fileDiff) =>
					normalizePath(fileDiff.name) === currentPath ||
					normalizePath(fileDiff.prevName) === currentPath,
			) || null
		)
	}, [diffs, currentPath])
	const fileAnnotations = useMemo(
		() => annotations.filter((annotation) => annotation.path === currentPath),
		[annotations, currentPath],
	)
	const selectedLines = useMemo(() => {
		if (!activeRange || activeRange.path !== currentPath) return undefined
		return {
			start: activeRange.start,
			end: activeRange.end,
			side: activeRange.side,
			endSide: activeRange.endSide || activeRange.side,
		}
	}, [activeRange, currentPath])

	useEffect(() => {
		const host = diffRef.current
		if (!host || !currentDiff) return undefined

		host.innerHTML = ''
		try {
			let instance = null
			const showSelection = (range) => {
				if (range) instance?.setSelectedLines(range)
			}
			instance = new diffsLib.FileDiff({
				theme: {dark: 'pierre-dark', light: 'pierre-light'},
				themeType: 'system',
				diffStyle: layout,
				diffIndicators: 'bars',
				hunkSeparators: 'line-info-basic',
				lineDiffType: 'word-alt',
				overflow: 'scroll',
				enableGutterUtility: true,
				enableLineSelection: true,
				lineHoverHighlight: 'both',
				onLineSelectionStart: showSelection,
				onLineSelectionChange: showSelection,
				onLineSelectionEnd: showSelection,
				onGutterUtilityClick: (range) => {
					showSelection(range)
					onAddAnnotation(range)
				},
				renderAnnotation: (annotation) => {
					const mount = document.createElement('div')
					render(
						html`<${AnnotationCard}
							annotation=${annotation.metadata.annotation}
							onDelete=${onDeleteAnnotation}
							inline=${true}
						/>`,
						mount,
					)
					return mount
				},
				renderHeaderMetadata: () => {
					const span = document.createElement('span')
					const count = fileAnnotations.length
					span.textContent =
						count === 1 ? '1 annotation' : count + ' annotations'
					return span
				},
			})
			instance.render({
				fileDiff: currentDiff,
				selectedLines,
				lineAnnotations: fileAnnotations.map((annotation) => ({
					side: annotation.side,
					lineNumber: annotation.start,
					metadata: {annotation},
				})),
				containerWrapper: host,
			})
			return () => instance.cleanUp()
		} catch (error) {
			console.error(error)
			host.innerHTML = '<pre class="raw-patch">' + escapeHtml(patch) + '</pre>'
		}
		return undefined
	}, [
		currentDiff,
		layout,
		fileAnnotations,
		selectedLines,
		onAddAnnotation,
		onDeleteAnnotation,
		patch,
	])

	if (!patch.trim()) {
		return html`<p class="empty">No diff found.</p>`
	}

	if (!currentDiff) {
		return html`<p class="empty">Select a file to view its diff.</p>`
	}

	return html`<div ref=${diffRef} class="diff-host"></div>`
}

const SidebarResizeHandle = ({side, width, onPointerDown, onKeyDown}) => html`
	<div
		class=${'resize-handle resize-handle-' + side}
		role="separator"
		aria-orientation="vertical"
		aria-label=${side === 'left'
			? 'Resize file sidebar'
			: 'Resize review sidebar'}
		aria-valuemin=${MIN_SIDEBAR_WIDTH}
		aria-valuemax=${MAX_SIDEBAR_WIDTH}
		aria-valuenow=${width}
		tabindex="0"
		title="Drag to resize"
		onPointerDown=${onPointerDown}
		onKeyDown=${onKeyDown}
	></div>
`

const ConflictViewer = ({file, onSave}) => {
	const hostRef = useRef(null)
	const [contents, setContents] = useState(file.contents)
	const [saving, setSaving] = useState(false)
	const [saveStatus, setSaveStatus] = useState(null)
	const unresolved = hasConflictMarkers(contents)

	useEffect(() => {
		setContents(file.contents)
		setSaveStatus(null)
	}, [file.path, file.contents])

	useEffect(() => {
		const host = hostRef.current
		if (!host) return undefined
		host.innerHTML = ''
		let currentContents = file.contents
		try {
			const instance = new diffsLib.UnresolvedFile({
				theme: {dark: 'pierre-dark', light: 'pierre-light'},
				diffIndicators: 'bars',
				onMergeConflictAction(payload) {
					currentContents = resolveMergeConflict(currentContents, payload)
					setContents(currentContents)
					instance.render({
						file: {name: file.path, contents: currentContents},
						containerWrapper: host,
					})
				},
			})
			instance.render({
				file: {name: file.path, contents: currentContents},
				containerWrapper: host,
			})
			return () => instance.cleanUp()
		} catch (error) {
			console.error(error)
			host.innerHTML =
				'<pre class="raw-patch">' + escapeHtml(file.contents) + '</pre>'
		}
		return undefined
	}, [file.path, file.contents])

	const save = async () => {
		setSaving(true)
		setSaveStatus(null)
		try {
			await onSave(file.path, contents)
			setSaveStatus(
				unresolved
					? 'Saved, but conflict markers remain.'
					: 'Saved and marked resolved.',
			)
		} catch (error) {
			setSaveStatus(error.message)
		} finally {
			setSaving(false)
		}
	}

	return html`
		<div class="conflict-viewer">
			<div class="conflict-toolbar">
				<div>
					<div class="conflict-title">Merge conflict</div>
					<div class="conflict-path">${file.path}</div>
				</div>
				<div class="conflict-actions">
					${saveStatus
						? html`<span
								class=${'conflict-save-status' +
								(saveStatus.startsWith('Saved') ? ' ok' : ' error')}
								>${saveStatus}</span
							>`
						: null}
					<button
						class=${unresolved ? '' : 'primary'}
						type="button"
						disabled=${saving}
						onClick=${save}
					>
						${unresolved ? 'Save partial resolution' : 'Save resolved file'}
					</button>
				</div>
			</div>
			<div ref=${hostRef} class="conflict-host"></div>
		</div>
	`
}

const ReviewPanel = ({
	note,
	setNote,
	annotations,
	onDeleteAnnotation,
	onAddReply,
	onDeleteReply,
	onJump,
}) => html`
	<aside id="rightSidebar" class="annotations">
		<div class="sidebar-header">
			<span>Review</span>
			<button
				class="sidebar-close"
				type="button"
				aria-label="Close annotations"
				onClick=${() => onJump(null)}
			>
				×
			</button>
		</div>
		<div class="panel-title">Review note</div>
		<textarea
			class="note"
			placeholder="Optional summary for pi…"
			value=${note}
			onInput=${(event) => setNote(event.currentTarget.value)}
		></textarea>
		<div class="panel-title" style=${{marginTop: '16px'}}>Annotations</div>
		<div class="annotation-list">
			${annotations.length === 0
				? html`<p class="empty">No annotations yet.</p>`
				: annotations.map(
						(annotation) =>
							html`<${AnnotationCard}
								key=${annotation.id}
								annotation=${annotation}
								onDelete=${onDeleteAnnotation}
								onJump=${onJump}
								onAddReply=${onAddReply}
								onDeleteReply=${onDeleteReply}
							/>`,
					)}
		</div>
		<p class="empty">
			Click the + gutter button in the diff to add a line annotation. pi can add
			annotations and replies through its own tools while this tab stays open.
		</p>
	</aside>
`

const AnnotationModal = ({range, text, setText, onCancel, onSave}) => html`
	<div
		class="modal-backdrop"
		hidden=${!range}
		onClick=${(event) => {
			if (event.currentTarget === event.target) onCancel()
		}}
	>
		<div
			class="modal"
			role="dialog"
			aria-modal="true"
			aria-labelledby="modalTitle"
		>
			<h2 id="modalTitle">Add annotation</h2>
			<p class="empty">
				${range ? annotationLocation({...range, text: ''}) : ''}
			</p>
			<textarea
				placeholder="Write the annotation to send back to pi…"
				value=${text}
				onInput=${(event) => setText(event.currentTarget.value)}
				autofocus=${true}
			></textarea>
			<div class="modal-actions">
				<button type="button" onClick=${onCancel}>Cancel</button>
				<button class="primary" type="button" onClick=${onSave}>
					Save annotation
				</button>
			</div>
		</div>
	</div>
`

const App = () => {
	const [status, setStatus] = useState({message: 'Starting…'})
	const [snapshot, setSnapshot] = useState(null)
	const [patch, setPatch] = useState('')
	const [files, setFiles] = useState([])
	const [conflicts, setConflicts] = useState([])
	const [diffs, setDiffs] = useState([])
	const [currentPath, setCurrentPath] = useState(null)
	const [layout, setLayout] = useState('split')
	const [annotations, setAnnotations] = useState([])
	const [note, setNote] = useState('')
	const [sidebar, setSidebar] = useState(null)
	const [modalRange, setModalRange] = useState(null)
	const [modalText, setModalText] = useState('')
	const [activeRange, setActiveRange] = useState(null)
	const [submitting, setSubmitting] = useState(false)
	const [leftSidebarWidth, setLeftSidebarWidth] = useState(() =>
		readNumberPreference(LEFT_SIDEBAR_WIDTH_KEY, 280),
	)
	const [rightSidebarWidth, setRightSidebarWidth] = useState(() =>
		readNumberPreference(RIGHT_SIDEBAR_WIDTH_KEY, 340),
	)

	const displayFiles = useMemo(
		() => mergeFileLists(files, conflicts),
		[files, conflicts],
	)
	const currentConflict = useMemo(
		() => conflicts.find((conflict) => conflict.path === currentPath) || null,
		[conflicts, currentPath],
	)

	const applySnapshot = useCallback((nextSnapshot) => {
		const nextPatch = nextSnapshot.patch || ''
		const fallbackFiles = Array.isArray(nextSnapshot.files)
			? nextSnapshot.files
			: []
		const parsed = parsePatchWithDiffs(nextPatch, fallbackFiles)
		setSnapshot(nextSnapshot)
		setPatch(nextPatch)
		setFiles(parsed.files)
		setDiffs(parsed.diffs)
		setCurrentPathFromFiles(setCurrentPath, parsed.files)
		setStatus({message: 'Ready', kind: 'ok'})
	}, [])

	const closeSidebars = useCallback(() => setSidebar(null), [])
	const selectPath = useCallback(
		(path) => {
			if (path) setCurrentPath(path)
			closeSidebars()
		},
		[closeSidebars],
	)

	const loadConflicts = useCallback(async () => {
		const result = await api('/api/conflicts')
		const nextConflicts = Array.isArray(result?.files) ? result.files : []
		setConflicts(nextConflicts)
		return nextConflicts
	}, [])

	const refresh = useCallback(async () => {
		setStatus({message: 'Loading diff…'})
		applySnapshot(await api('/api/diff'))
		const nextConflicts = await loadConflicts()
		setStatus({
			message:
				nextConflicts.length > 0
					? `Ready · ${nextConflicts.length} conflict(s)`
					: 'Ready',
			kind: 'ok',
		})
	}, [applySnapshot, loadConflicts])

	const deleteAnnotation = useCallback(async (id) => {
		setActiveRange((current) => (current?.id === id ? null : current))
		await api('/api/annotations/delete', {
			method: 'POST',
			body: JSON.stringify({id}),
		})
	}, [])

	const addReply = useCallback(async (annotationId, text) => {
		await api('/api/replies', {
			method: 'POST',
			body: JSON.stringify({annotationId, text, author: 'user'}),
		})
	}, [])

	const deleteReply = useCallback(async (annotationId, replyId) => {
		await api('/api/replies/delete', {
			method: 'POST',
			body: JSON.stringify({annotationId, replyId}),
		})
	}, [])

	const saveConflict = useCallback(async (path, contents) => {
		const result = await api('/api/conflicts/write', {
			method: 'POST',
			body: JSON.stringify({path, contents}),
		})
		const savedFile = result?.file
		if (!savedFile) return
		setConflicts((current) => {
			if (savedFile.resolved) {
				return current.filter((conflict) => conflict.path !== savedFile.path)
			}
			return current.map((conflict) =>
				conflict.path === savedFile.path ? savedFile : conflict,
			)
		})
	}, [])

	const addAnnotation = useCallback(
		(range) => {
			if (!currentPath) return
			const side = range.side === 'deletions' ? 'deletions' : 'additions'
			const start = Number.isFinite(range.start)
				? range.start
				: range.lineNumber || 1
			const end = Number.isFinite(range.end) ? range.end : start
			const nextRange = {
				path: currentPath,
				side,
				start: Math.max(1, Math.trunc(start)),
				end: Math.max(1, Math.trunc(end)),
				endSide: range.endSide === 'deletions' ? 'deletions' : side,
			}
			setActiveRange(nextRange)
			setModalRange(nextRange)
			setModalText('')
		},
		[currentPath],
	)

	const saveAnnotation = useCallback(async () => {
		const text = modalText.trim()
		if (!modalRange || !text) return
		const result = await api('/api/annotations', {
			method: 'POST',
			body: JSON.stringify({
				annotation: {...modalRange, text, author: 'user'},
			}),
		})
		setModalRange(null)
		setModalText('')
		if (result?.annotation) setActiveRange(result.annotation)
	}, [modalRange, modalText])

	const submitAnnotations = useCallback(async () => {
		if (annotations.length === 0 && !note.trim()) {
			const ok = confirm('Send an empty review to pi?')
			if (!ok) return
		}
		setSubmitting(true)
		setStatus({message: 'Sending annotations to pi…'})
		try {
			await api('/api/submit', {
				method: 'POST',
				body: JSON.stringify({note: note.trim()}),
			})
			setStatus({
				message: 'Sent to pi. Keep this tab open for follow-up replies.',
				kind: 'ok',
			})
		} catch (error) {
			setStatus({message: error.message, kind: 'error'})
		} finally {
			setSubmitting(false)
		}
	}, [annotations, note])

	const cancelServer = useCallback(() => {
		setStatus({message: 'Closing server…'})
		void fetch(apiUrl('/api/cancel'), {
			method: 'POST',
			headers: {'Content-Type': 'application/json'},
			body: '{}',
			keepalive: true,
		}).catch(console.error)
		closeThisTab()
	}, [])

	const startSidebarResize = useCallback(
		(side, event) => {
			event.preventDefault()
			const startX = event.clientX
			const startWidth = side === 'left' ? leftSidebarWidth : rightSidebarWidth
			const setWidth =
				side === 'left' ? setLeftSidebarWidth : setRightSidebarWidth
			document.body.classList.add('resizing-sidebar')
			const onPointerMove = (moveEvent) => {
				const delta = moveEvent.clientX - startX
				const nextWidth =
					side === 'left' ? startWidth + delta : startWidth - delta
				setWidth(clamp(nextWidth, MIN_SIDEBAR_WIDTH, MAX_SIDEBAR_WIDTH))
			}
			const onPointerUp = () => {
				document.body.classList.remove('resizing-sidebar')
				window.removeEventListener('pointermove', onPointerMove)
				window.removeEventListener('pointerup', onPointerUp)
				window.removeEventListener('pointercancel', onPointerUp)
			}
			window.addEventListener('pointermove', onPointerMove)
			window.addEventListener('pointerup', onPointerUp)
			window.addEventListener('pointercancel', onPointerUp)
		},
		[leftSidebarWidth, rightSidebarWidth],
	)

	const resizeSidebarByKeyboard = useCallback((side, event) => {
		const step = event.shiftKey ? 40 : 16
		const setters = {
			left: setLeftSidebarWidth,
			right: setRightSidebarWidth,
		}
		let delta = 0
		if (event.key === 'ArrowLeft') delta = side === 'left' ? -step : step
		else if (event.key === 'ArrowRight') delta = side === 'left' ? step : -step
		else if (event.key === 'Home') delta = Number.NEGATIVE_INFINITY
		else if (event.key === 'End') delta = Number.POSITIVE_INFINITY
		else return
		event.preventDefault()
		setters[side]((current) => {
			if (delta === Number.NEGATIVE_INFINITY) return MIN_SIDEBAR_WIDTH
			if (delta === Number.POSITIVE_INFINITY) return MAX_SIDEBAR_WIDTH
			return clamp(current + delta, MIN_SIDEBAR_WIDTH, MAX_SIDEBAR_WIDTH)
		})
	}, [])

	useEffect(() => {
		writeNumberPreference(LEFT_SIDEBAR_WIDTH_KEY, leftSidebarWidth)
	}, [leftSidebarWidth])

	useEffect(() => {
		writeNumberPreference(RIGHT_SIDEBAR_WIDTH_KEY, rightSidebarWidth)
	}, [rightSidebarWidth])

	useEffect(() => {
		setCurrentPathFromFiles(setCurrentPath, displayFiles)
	}, [displayFiles])

	useEffect(() => {
		document.body.classList.toggle('left-sidebar-open', sidebar === 'left')
		document.body.classList.toggle('right-sidebar-open', sidebar === 'right')
		return () => {
			document.body.classList.remove('left-sidebar-open', 'right-sidebar-open')
		}
	}, [sidebar])

	useEffect(() => {
		const query = window.matchMedia('(max-width: 1100px)')
		const onChange = (event) => {
			if (!event.matches) closeSidebars()
		}
		query.addEventListener('change', onChange)
		return () => query.removeEventListener('change', onChange)
	}, [closeSidebars])

	useEffect(() => {
		const onKeyDown = (event) => {
			if (event.key === 'Escape' && modalRange) setModalRange(null)
			else if (event.key === 'Escape') closeSidebars()
			if (
				(event.metaKey || event.ctrlKey) &&
				event.key === 'Enter' &&
				modalRange
			) {
				event.preventDefault()
				void saveAnnotation()
			}
		}
		window.addEventListener('keydown', onKeyDown)
		return () => window.removeEventListener('keydown', onKeyDown)
	}, [closeSidebars, modalRange, saveAnnotation])

	useEffect(() => {
		let cancelled = false
		const boot = async () => {
			try {
				setStatus({message: 'Loading diff…'})
				const initialSnapshot = await api('/api/diff')
				if (cancelled) return
				applySnapshot(initialSnapshot)
				const initialConflicts = await loadConflicts()
				if (!cancelled && initialConflicts.length > 0) {
					setStatus({
						message: `Ready · ${initialConflicts.length} conflict(s)`,
						kind: 'ok',
					})
				}
			} catch (error) {
				if (!cancelled) setStatus({message: error.message, kind: 'error'})
			}
		}
		void boot()
		return () => {
			cancelled = true
		}
	}, [applySnapshot, loadConflicts])

	useEffect(() => {
		const source = new EventSource(apiUrl('/api/events'))
		source.addEventListener('annotations', (event) => {
			try {
				const payload = JSON.parse(event.data)
				if (Array.isArray(payload?.annotations)) {
					setAnnotations(payload.annotations)
				}
			} catch (error) {
				console.error(error)
			}
		})
		source.addEventListener('error', () => {
			// EventSource auto-reconnects; just surface the disconnect.
			setStatus((current) =>
				current.kind === 'error'
					? current
					: {message: 'Reconnecting to review server…', kind: 'error'},
			)
		})
		return () => source.close()
	}, [])

	const subtitle = snapshot
		? (snapshot.source?.label || snapshot.vcs) +
			' · ' +
			snapshot.command +
			' · ' +
			displayFiles.length +
			' file(s)' +
			(conflicts.length > 0 ? ` · ${conflicts.length} conflict(s)` : '')
		: 'Loading diff…'

	return html`
		<div class="app">
			<${Header}
				status=${status}
				subtitle=${subtitle}
				layout=${layout}
				onToggleLayout=${() =>
					setLayout((current) => (current === 'split' ? 'unified' : 'split'))}
				onRefresh=${refresh}
				onSubmit=${submitAnnotations}
				onCancel=${cancelServer}
				submitting=${submitting}
			/>
			<main
				class="main"
				style=${{
					'--left-sidebar-width': leftSidebarWidth + 'px',
					'--right-sidebar-width': rightSidebarWidth + 'px',
				}}
			>
				<button
					class="sidebar-toggle sidebar-toggle-left"
					type="button"
					aria-label="Open file list"
					aria-controls="leftSidebar"
					aria-expanded=${sidebar === 'left'}
					onClick=${() => setSidebar(sidebar === 'left' ? null : 'left')}
				>
					☰
				</button>
				<button
					class="sidebar-toggle sidebar-toggle-right"
					type="button"
					aria-label="Open annotations"
					aria-controls="rightSidebar"
					aria-expanded=${sidebar === 'right'}
					onClick=${() => setSidebar(sidebar === 'right' ? null : 'right')}
				>
					✎
				</button>
				<div
					class="sidebar-backdrop"
					hidden=${!sidebar}
					onClick=${closeSidebars}
				></div>
				<aside id="leftSidebar" class="sidebar">
					<div class="sidebar-header">
						<span>Files</span>
						<button
							class="sidebar-close"
							type="button"
							aria-label="Close file list"
							onClick=${closeSidebars}
						>
							×
						</button>
					</div>
					<${FileTreePanel}
						files=${displayFiles}
						currentPath=${currentPath}
						onSelect=${selectPath}
					/>
				</aside>
				<${SidebarResizeHandle}
					side="left"
					width=${leftSidebarWidth}
					onPointerDown=${(event) => startSidebarResize('left', event)}
					onKeyDown=${(event) => resizeSidebarByKeyboard('left', event)}
				/>
				<section class="diff-wrap">
					${currentConflict
						? html`<${ConflictViewer}
								file=${currentConflict}
								onSave=${saveConflict}
							/>`
						: html`<${DiffViewer}
								patch=${patch}
								diffs=${diffs}
								currentPath=${currentPath}
								layout=${layout}
								annotations=${annotations}
								activeRange=${activeRange}
								onAddAnnotation=${addAnnotation}
								onDeleteAnnotation=${deleteAnnotation}
							/>`}
				</section>
				<${SidebarResizeHandle}
					side="right"
					width=${rightSidebarWidth}
					onPointerDown=${(event) => startSidebarResize('right', event)}
					onKeyDown=${(event) => resizeSidebarByKeyboard('right', event)}
				/>
				<${ReviewPanel}
					note=${note}
					setNote=${setNote}
					annotations=${annotations}
					onDeleteAnnotation=${deleteAnnotation}
					onAddReply=${addReply}
					onDeleteReply=${deleteReply}
					onJump=${(path, annotation) => {
						if (annotation) setActiveRange(annotation)
						path ? selectPath(path) : closeSidebars()
					}}
				/>
			</main>
			<${AnnotationModal}
				range=${modalRange}
				text=${modalText}
				setText=${setModalText}
				onCancel=${() => setModalRange(null)}
				onSave=${saveAnnotation}
			/>
		</div>
	`
}

render(html`<${App} />`, document.getElementById('app'))
