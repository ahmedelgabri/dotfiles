local au = require '_.utils.au'

au.augroup('__MyCustomColors__', {
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
vim.cmd.colorscheme 'plain'
