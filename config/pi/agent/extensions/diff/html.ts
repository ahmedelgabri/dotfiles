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

export const renderHtml = (token: string): string => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
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
				<div class="title">pi diff review</div>
				<div class="subtitle">Loading UI…</div>
			</div>
			<span id="status" class="status">Starting…</span>
		</header>
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
window.PI_DIFF_CONFIG = ${json({token})}
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
