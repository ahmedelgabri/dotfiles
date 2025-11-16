if vim.fn.executable 'rg' == 1 then
	vim.o.grepprg = 'rg --vimgrep --smart-case --hidden'
end

vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
vim.keymap.set(
	'n',
	'\\',
	[[:silent grep!  | cwindow<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>]],
	{ desc = 'Grep' }
)
