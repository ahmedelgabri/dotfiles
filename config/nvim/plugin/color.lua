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

-- Order is important, so autocmds above works properly
vim.opt.background = 'dark'
vim.cmd [[silent! colorscheme plain-lua]]
