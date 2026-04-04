return {
	{ 'https://github.com/tpope/vim-repeat' },
	{
		'https://github.com/wincent/loupe',
		event = 'VeryLazy',
		init = function()
			vim.g.LoupeClearHighlightMap = 0
			-- Not needed in Neovim (see `:help hl-CurSearch`).
			vim.g.LoupeHighlightGroup = ''

			local au = require '_.utils.au'
			local hl = require '_.utils.highlight'

			local function set_up_loupe_highlight()
				hl.group('QuickFixLine', { link = 'PmenuSel' })
				vim.cmd 'highlight! clear Search'
				hl.group('Search', { link = 'Underlined' })
			end

			au.augroup('__myloupe__', {
				{
					event = 'ColorScheme',
					pattern = '*',
					callback = set_up_loupe_highlight,
				},
			})

			set_up_loupe_highlight()
		end,
	},
	{
		'https://github.com/alexghergh/nvim-tmux-navigation',
		opts = {
			disable_when_zoomed = true,
			keybindings = {
				left = '<C-h>',
				down = '<C-j>',
				up = '<C-k>',
				right = '<C-l>',
			},
		},
	},
	{
		'https://github.com/kevinhwang91/nvim-bqf',
		ft = 'qf',
		dependencies = {
			-- https://github.com/kevinhwang91/nvim-bqf/issues/83#issuecomment-1296321476
			{
				'https://github.com/junegunn/fzf',
				name = 'fzf',
				config = function() end,
			},
		},
	},
	{
		'https://github.com/jbyuki/venn.nvim',
		keys = {
			{
				'<leader>v',
				function()
					local venn_enabled = vim.inspect(vim.b.venn_enabled)
					if venn_enabled == 'nil' then
						vim.b.venn_enabled = true

						vim.wo.virtualedit = 'all'

						-- draw a line on HJKL keystrokes
						vim.keymap.set('n', 'J', '<C-v>j:VBox<CR>', { buf = 0 })
						vim.keymap.set('n', 'K', '<C-v>k:VBox<CR>', { buf = 0 })
						vim.keymap.set('n', 'L', '<C-v>l:VBox<CR>', { buf = 0 })
						vim.keymap.set('n', 'H', '<C-v>h:VBox<CR>', { buf = 0 })
						-- draw a box by pressing "f" with visual selection
						vim.keymap.set('v', 'f', ':VBox<CR>', { buf = 0 })
					else
						vim.wo.virtualedit = ''

						vim.keymap.del('n', 'J', { buf = 0 })
						vim.keymap.del('n', 'K', { buf = 0 })
						vim.keymap.del('n', 'L', { buf = 0 })
						vim.keymap.del('n', 'H', { buf = 0 })
						vim.keymap.del('v', 'f', { buf = 0 })

						vim.b.venn_enabled = nil
					end
				end,
				noremap = true,
				desc = 'Enable [V]enn diagramming mode',
			},
		},
	},
	{ 'https://github.com/fladson/vim-kitty', ft = 'kitty' },
	{
		'ghostty',
		ft = { 'ghostty' },
		dir = '/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/',
	},
	{
		'https://github.com/MagicDuck/grug-far.nvim',
		event = 'FileType grug-far',
		cmd = { 'GrugFar' },
		opts = function(_, opts)
			local utils = require '_.utils'
			local node_modules_ast_grep = utils.get_lsp_bin 'ast-grep'

			-- Prefer local binaries over global ones
			if node_modules_ast_grep then
				return vim.tbl_deep_extend('force', opts or {}, {
					engines = {
						astgrep = {
							path = node_modules_ast_grep,
						},
					},
				})
			end

			return opts
		end,
	},
	{
		'https://github.com/slugbyte/lackluster.nvim',
		enabled = false,
		lazy = false,
		priority = 1000,
		init = function()
			vim.cmd.colorscheme 'lackluster'
		end,
		opts = function(_, opts)
			local color = require 'lackluster.color'

			return vim.tbl_deep_extend('force', opts or {}, {
				tweak_color = {
					-- I don't like the default warning colors, etc...
					orange = color.yellow,
					red = color.orange,
				},
				tweak_highlight = {
					Comment = { italic = true },
					['@comment'] = { link = 'Comment' },

					Removed = { fg = color.orange },
					DiffRemove = { link = 'Removed' },
					DiffRemoved = { link = 'Removed' },
					DiffDelete = { link = 'Removed' },
					['@diff.minus'] = { link = 'Removed' },

					Changed = { fg = color.yellow },
					Change = { link = 'Changed' },
					DiffChange = { link = 'Changed' },
					['@diff.delta'] = { link = 'Changed' },

					DiagnosticInfo = { fg = color.blue },
					DiagnosticSignInfo = { link = 'DiagnosticInfo' },
					DiagnosticHint = { fg = color.lack },
					DiagnosticSignHint = { link = 'DiagnosticHint' },
					DiagnosticWarn = { link = 'Changed' },
					DiagnosticSignWarn = { link = 'DiagnosticWarn' },

					DiagnosticDeprecated = { strikethrough = true },

					['@markup.italic'] = { italic = true },
					['@markup.emphasis'] = { link = '@markup.italic' },
					['@markup.strong'] = { bold = true, fg = 'NONE' },

					StatusLine = { fg = color.gray4, bg = 'NONE' },
					StatusLineNC = { bg = 'NONE' },

					TabLine = { bg = 'NONE' },

					WinBar = { bg = 'NONE' },
					WinBarNC = { bg = 'NONE' },

					User6 = { fg = color.gray6 },

					MiniIndentScopeSymbol = { fg = color.gray3 },
				},
				disable_plugin = {
					navic = true,
				},
			})
		end,
	},
	{
		'https://github.com/hedyhli/outline.nvim',
		cmd = { 'Outline', 'OutlineOpen' },
		opts = {},
	},
	{
		'https://github.com/saghen/blink.indent',
		--- @module 'blink.indent'
		--- @type blink.indent.Config
		opts = {
			static = {
				enabled = false,
				char = '▎',
			},
			scope = {
				char = '▎',
				highlights = { 'BlinkIndentScope' },
			},
		},
	},
}
