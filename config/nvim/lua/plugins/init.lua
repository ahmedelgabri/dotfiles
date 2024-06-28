return {
	{
		'https://github.com/tpope/tpope-vim-abolish',
		cmd = { 'Abolish', 'S', 'Subvert' },
	},
	{ 'https://github.com/tpope/vim-repeat' },
	{
		'https://github.com/wincent/loupe',
		event = 'VeryLazy',
		init = function()
			local au = require '_.utils.au'
			local hl = require '_.utils.highlight'

			function SetUpLoupeHighlight()
				hl.group('QuickFixLine', { link = 'PmenuSel' })
				vim.cmd 'highlight! clear Search'
				hl.group('Search', { link = 'Underlined' })
			end

			au.augroup('__myloupe__', {
				{
					event = 'ColorScheme',
					pattern = '*',
					callback = SetUpLoupeHighlight,
				},
			})

			SetUpLoupeHighlight()
		end,
	},
	{
		'https://github.com/christoomey/vim-tmux-navigator',
		lazy = false,
		init = function()
			vim.g.tmux_navigator_disable_when_zoomed = 1
		end,
	},
	{ 'https://github.com/kevinhwang91/nvim-bqf', ft = 'qf' },
}
