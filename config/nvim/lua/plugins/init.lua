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
			vim.g.LoupeClearHighlightMap = 0

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
	{ 'https://github.com/mistweaverco/kulala.nvim', ft = 'http', config = true },
	{
		'https://github.com/jbyuki/venn.nvim',
		keys = {
			{
				'<leader>v',
				function()
					local venn_enabled = vim.inspect(vim.b.venn_enabled)
					if venn_enabled == 'nil' then
						vim.b.venn_enabled = true

						vim.cmd [[setlocal ve=all]]

						-- draw a line on HJKL keystrokes
						vim.keymap.set('n', 'J', '<C-v>j:VBox<CR>', { buffer = true })
						vim.keymap.set('n', 'K', '<C-v>k:VBox<CR>', { buffer = true })
						vim.keymap.set('n', 'L', '<C-v>l:VBox<CR>', { buffer = true })
						vim.keymap.set('n', 'H', '<C-v>h:VBox<CR>', { buffer = true })
						-- draw a box by pressing "f" with visual selection
						vim.keymap.set('v', 'f', ':VBox<CR>', { buffer = true })
					else
						vim.cmd [[setlocal ve=]]

						vim.keymap.del('n', 'J', { buffer = true })
						vim.keymap.del('n', 'K', { buffer = true })
						vim.keymap.del('n', 'L', { buffer = true })
						vim.keymap.del('n', 'H', { buffer = true })
						vim.keymap.del('v', 'f', { buffer = true })

						vim.b.venn_enabled = nil
					end
				end,
				noremap = true,
				desc = 'Enable [V]enn diagramming mode',
			},
		},
	},
	{ 'https://github.com/pteroctopus/faster.nvim' },
	{ 'https://github.com/fladson/vim-kitty', ft = 'kitty' },
	{
		'https://github.com/MagicDuck/grug-far.nvim',
		event = 'FileType grug-far',
		cmd = { 'GrugFar' },
		config = true,
	},
}
