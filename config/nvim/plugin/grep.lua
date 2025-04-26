if vim.fn.executable 'rg' == 0 then
	return
end

vim.o.grepprg = 'rg --vimgrep --smart-case --hidden'
vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
vim.keymap.set(
	'n',
	'\\',
	[[:silent grep!  | cwindow<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>]],
	{ desc = 'Grep' }
)
