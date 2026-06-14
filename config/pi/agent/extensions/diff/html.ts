import {readFileSync} from 'node:fs'
import {fileURLToPath} from 'node:url'

const DIFFS_CDN = 'https://esm.sh/@pierre/diffs@1.1.21?bundle&target=es2022'
const TREES_CDN =
	'https://esm.sh/@pierre/trees@1.0.0-beta.3?bundle&target=es2022'
const PREACT_CDN = 'https://esm.sh/preact@10.25.4?target=es2022'
const PREACT_HOOKS_CDN = 'https://esm.sh/preact@10.25.4/hooks?target=es2022'
const HTM_PREACT_CDN =
	'https://esm.sh/htm@3.1.1/preact?external=preact&target=es2022'
const MARKED_CDN = 'https://esm.sh/marked@18.0.3?target=es2022'
const DOMPURIFY_CDN = 'https://esm.sh/dompurify@3.4.2?target=es2022'

const json = (value: unknown): string =>
	JSON.stringify(value).replace(/</g, '\\u003c')

const FAVICON_SVG =
	`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">` +
	`<rect width="32" height="32" rx="7" fill="#0d0e11"/>` +
	`<g fill="none" stroke="#f0b429" stroke-width="2.6" stroke-linecap="round">` +
	`<path d="M7 12h18"/><path d="M12.6 12v9"/><path d="M21 12v8.4"/>` +
	`</g></svg>`

const FAVICON = `data:image/svg+xml,${encodeURIComponent(FAVICON_SVG)}`

const CLIENT_SCRIPT = readFileSync(
	fileURLToPath(new URL('./client.js', import.meta.url)),
	'utf8',
)

const STYLES = readFileSync(
	fileURLToPath(new URL('./styles.css', import.meta.url)),
	'utf8',
)

const clientScript = (): string =>
	CLIENT_SCRIPT.replace(/<\/script/gi, '<\\/script')

const styles = (): string => STYLES.replace(/<\/style/gi, '<\\/style')

export const renderHtml = (token: string, ui?: unknown): string => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#f3f1ea" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0d0e11" media="(prefers-color-scheme: dark)">
<link rel="icon" href="${FAVICON}">
<link rel="preconnect" href="https://esm.sh" crossorigin>
<title>pi diff review</title>
<style>
${styles()}
</style>
</head>
<body>
<div id="app">
	<div class="loading-shell">
		<header class="header">
			<div>
				<div class="title">
					<span class="brand-mark" aria-hidden="true">π</span>
					<span class="wordmark">pi diff review</span>
				</div>
				<div class="subtitle">Booting review instrument…</div>
			</div>
			<span id="status" class="status">Starting…</span>
		</header>
		<div class="boot-stage" aria-hidden="true">
			<div class="boot-mark">π</div>
		</div>
	</div>
</div>
<script type="importmap">
${json({
	imports: {
		preact: PREACT_CDN,
		'preact/hooks': PREACT_HOOKS_CDN,
		'htm/preact': HTM_PREACT_CDN,
		marked: MARKED_CDN,
		dompurify: DOMPURIFY_CDN,
		'@pierre/diffs': DIFFS_CDN,
		'@pierre/trees': TREES_CDN,
	},
})}
</script>
<script>
window.PI_DIFF_CONFIG = ${json({token, ui: ui ?? null})}
const RESIZE_OBSERVER_NOISE = /^ResizeObserver loop/i
window.addEventListener('error', (event) => {
	if (RESIZE_OBSERVER_NOISE.test(event.message || '')) {
		event.stopImmediatePropagation()
		return
	}
	const status = document.getElementById('status')
	if (status) {
		status.textContent = event.message || 'Browser script error'
		status.className = 'status error'
	}
})
window.addEventListener('unhandledrejection', (event) => {
	const message = event.reason?.message || ''
	if (RESIZE_OBSERVER_NOISE.test(message)) {
		event.preventDefault()
		return
	}
	const status = document.getElementById('status')
	if (status) {
		status.textContent = message || 'Browser promise error'
		status.className = 'status error'
	}
})
</script>
<script type="module">
${clientScript()}
</script>
</body>
</html>
`
