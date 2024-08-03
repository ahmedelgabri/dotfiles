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
	-- Not needed since I have git-conflict.nvim
	-- {
	-- 	event = { 'BufWinEnter', 'BufEnter' },
	-- 	pattern = '*',
	-- 	callback = function()
	-- 		cmds.toggleHighlightPattern(
	-- 			'GitMarkers',
	-- 			'^\\(<\\|=\\|>\\)\\{7\\}\\([^=].\\+\\)\\?$'
	-- 		)
	-- 	end,
	-- },
	-- https://www.reddit.com/r/neovim/comments/1ehidxy/you_can_remove_padding_around_neovim_instance/
	{
		event = { 'UIEnter', 'ColorScheme' },
		callback = function()
			local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
			if not normal.bg then
				return
			end

			if vim.env.TMUX then
				io.write(
					string.format('\027Ptmux;\027\027]11;#%06x\007\027\\', normal.bg)
				)
			else
				io.write(string.format('\027]11;#%06x\027\\', normal.bg))
			end
		end,
	},
	{
		event = 'UILeave',
		callback = function()
			if vim.env.TMUX then
				io.write '\027Ptmux;\027\027]111;\007\027\\'
			else
				io.write '\027]111\027\\'
			end
		end,
	},
})

vim.opt.background = 'dark'
vim.cmd [[colorscheme plain]]
