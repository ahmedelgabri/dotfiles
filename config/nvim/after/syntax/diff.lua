local hl = require '_.utils.highlight'

-- I set this to % to be able to write Markdown in PRs & Issues
vim.fn.cmd [[syn match diffComment "^%.*]]

hl.group('diffAdded', {
	fg = 'darkgreen',
	bg = '#3DB65C',
	ctermfg = 'darkgreen',
	ctermbg = 'green',
	italic = true,
})

hl.group('diffRemoved', {
	fg = 'darkred',
	bg = '#F1544F',
	ctermfg = 'darkred',
	ctermbg = 'red',
	italic = true,
})

hl.group('diffChanged', {
	fg = 'darkorange',
	ctermfg = 'darkyellow',
})
