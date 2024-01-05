local au = require '_.utils.au'
local cmds = require '_.autocmds'

au.augroup('__MyCustomColors__', {
	{
		event = { 'BufWinEnter', 'BufEnter' },
		pattern = '?*',
		callback = cmds.highlight_overlength,
	},
	{
		event = 'OptionSet',
		pattern = 'textwidth',
		callback = cmds.highlight_overlength,
	},
	{
		event = { 'BufWinEnter', 'BufEnter' },
		pattern = '*',
		callback = cmds.highlight_git_markers,
	},
})

vim.opt.background = 'dark'
vim.cmd [[colorscheme plain]]
