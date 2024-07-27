local au = require '_.utils.au'
local cmds = require '_.autocmds'

local function toggleOverLength()
	if
		vim.wo.diff == true
		or vim.wo.previewwindow == true
		or cmds.colorcolumn_blocklist[vim.bo.filetype] == true
	then
		return
	end

	cmds.toggleHighlightPattern(
		'OverLength',
		string.format('\\%%>%dv.\\+', vim.bo.textwidth + 1) -- \%>81v.\+
	)
end

au.augroup('__MyCustomColors__', {
	{
		event = { 'BufWinEnter', 'BufEnter' },
		pattern = '?*',
		callback = toggleOverLength,
	},
	{
		event = 'OptionSet',
		pattern = 'textwidth',
		callback = toggleOverLength,
	},
	{
		event = { 'BufWinEnter', 'BufEnter' },
		pattern = '*',
		callback = function()
			if vim.fn.exists ':GitConflictRefresh' > 0 then
				return
			end

			cmds.toggleHighlightPattern(
				'GitMarkers',
				'^\\(<\\|=\\|>\\)\\{7\\}\\([^=].\\+\\)\\?$'
			)
		end,
	},
})

vim.opt.background = 'dark'
vim.cmd [[colorscheme plain]]
