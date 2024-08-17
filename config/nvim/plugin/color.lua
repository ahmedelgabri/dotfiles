local au = require '_.utils.au'
local cmds = require '_.autocmds'

au.augroup('__MyCustomColors__', {
	-- Not needed since I have git-conflict.nvim
	-- {
	-- 	event = { 'BufWinEnter', 'BufEnter' },
	-- 	pattern = '*',
	-- 	callback = function()
	-- 		local name = 'GitMarkers'
	-- 		local pattern = '^\\(<\\|=\\|>\\)\\{7\\}\\([^=].\\+\\)\\?$'
	--
	-- 		local key = name .. '_match_id'
	--
	-- 		if vim.b[key] ~= nil and vim.b[key] > 0 then
	-- 			vim.b[key] = vim.fn.matchdelete(vim.b[key])
	-- 		end
	--
	-- 		vim.b[key] = vim.fn.matchadd(name, pattern)
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
