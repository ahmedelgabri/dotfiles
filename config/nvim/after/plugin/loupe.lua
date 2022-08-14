local au = require '_.utils.au'
local hl = require '_.utils.highlight'

function SetUpLoupeHighlight()
	hl.group('QuickFixLine', { link = 'PmenuSel' })
	vim.cmd 'highlight! clear Search'
	hl.group('Search', { link = 'Underlined' })
end

au.augroup('__myloupe__', {
	{ event = 'ColorScheme', pattern = '*', callback = SetUpLoupeHighlight },
})

SetUpLoupeHighlight()

vim.keymap.set(
	{ 'n' },
	'<Leader>c',
	'<Plug>(LoupeClearHighlight)',
	{ remap = true }
)
