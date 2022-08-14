local au = require '_.utils.au'

-- New extensions: https://www.typescriptlang.org/docs/handbook/esm-node.html#new-file-extensions
au.autocmd {
	event = { 'BufNewFile', 'BufRead' },
	pattern = { '*.cts', '*.mts' },
	command = 'noautocmd set filetype=typescript',
}
