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
		'https://github.com/alexghergh/nvim-tmux-navigation',
		config = function()
			require('nvim-tmux-navigation').setup {
				disable_when_zoomed = true,
				keybindings = {
					left = '<C-h>',
					down = '<C-j>',
					up = '<C-k>',
					right = '<C-l>',
					last_active = '<C-\\>',
					next = '<C-Space>',
				},
			}
		end,
	},
	{ 'https://github.com/kevinhwang91/nvim-bqf', ft = 'qf' },
	{ 'https://github.com/stevearc/quicker.nvim', config = true },
	{ 'https://github.com/mistweaverco/kulala.nvim', ft = 'http' },
}
