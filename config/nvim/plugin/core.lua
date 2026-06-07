-- Core/misc plugins
local au = require '_.utils.au'
local pack = require '_.pack'

pack.add {
	{ src = 'https://github.com/tpope/vim-repeat', load = false },
	{
		src = 'https://github.com/alexghergh/nvim-tmux-navigation',
		load = false,
		event = vim.env.TMUX and { 'UIEnter' } or nil,
		config = function()
			require('nvim-tmux-navigation').setup {
				disable_when_zoomed = true,
				keybindings = {
					left = '<C-h>',
					down = '<C-j>',
					up = '<C-k>',
					right = '<C-l>',
				},
			}
		end,
	},
	{
		src = 'https://github.com/saghen/blink.indent',
		name = 'blink.indent',
		event = { 'UIEnter' },
		config = function()
			--- @module 'blink.indent'
			--- @type blink.indent.Config
			require('blink.indent').setup {
				static = {
					enabled = false,
					char = '▎',
				},
				scope = {
					char = '▎',
					highlights = { 'BlinkIndentScope' },
				},
			}
		end,
	},
	{
		src = 'https://github.com/wincent/loupe',
		event = { 'UIEnter' },
		config = function()
			local hl = require '_.utils.highlight'

			-- Loupe: load after startup (was event = 'VeryLazy')
			vim.g.LoupeClearHighlightMap = 0
			-- Not needed in Neovim (see `:help hl-CurSearch`).
			vim.g.LoupeHighlightGroup = ''

			local function set_up_loupe_highlight()
				hl.group('QuickFixLine', { link = 'PmenuSel' })
				vim.cmd 'highlight! clear Search'
				hl.group('Search', { link = 'Underlined' })
			end

			local loupe_group =
				vim.api.nvim_create_augroup('__myloupe__', { clear = true })
			vim.api.nvim_create_autocmd('ColorScheme', {
				group = loupe_group,
				pattern = '*',
				callback = set_up_loupe_highlight,
			})

			set_up_loupe_highlight()
		end,
	},
	{
		src = 'https://github.com/junegunn/fzf',
		name = 'fzf',
		ft = { 'qf' },
	},
	{ src = 'https://github.com/kevinhwang91/nvim-bqf', ft = { 'qf' } },
	{
		src = 'https://github.com/jbyuki/venn.nvim',
		config = function()
			vim.keymap.set('n', '<leader>v', function()
				if vim.b.venn_enabled == nil then
					vim.b.venn_enabled = true
					vim.wo.virtualedit = 'all'

					-- draw a line on HJKL keystrokes
					vim.keymap.set('n', 'J', '<C-v>j:VBox<CR>', { buf = 0 })
					vim.keymap.set('n', 'K', '<C-v>k:VBox<CR>', { buf = 0 })
					vim.keymap.set('n', 'L', '<C-v>l:VBox<CR>', { buf = 0 })
					vim.keymap.set('n', 'H', '<C-v>h:VBox<CR>', { buf = 0 })
					-- draw a box by pressing "f" with visual selection
					vim.keymap.set('v', 'f', ':VBox<CR>', { buf = 0 })
					return
				end

				vim.wo.virtualedit = ''
				vim.keymap.del('n', 'J', { buf = 0 })
				vim.keymap.del('n', 'K', { buf = 0 })
				vim.keymap.del('n', 'L', { buf = 0 })
				vim.keymap.del('n', 'H', { buf = 0 })
				vim.keymap.del('v', 'f', { buf = 0 })
				vim.b.venn_enabled = nil
			end, { noremap = true, desc = 'Enable [V]enn diagramming mode' })
		end,
	},
	{ src = 'https://github.com/fladson/vim-kitty', ft = { 'kitty' } },
	{
		src = 'https://github.com/MagicDuck/grug-far.nvim',
		cmd = { 'GrugFar' },
		ft = { 'grug-far' },
		config = function()
			local pack_utils = require '_.utils'
			local node_modules_ast_grep = pack_utils.get_lsp_bin 'ast-grep'
			local opts = {}

			-- Prefer local binaries over global ones
			if node_modules_ast_grep then
				opts = {
					engines = {
						astgrep = {
							path = node_modules_ast_grep,
						},
					},
				}
			end

			require('grug-far').setup(opts)
		end,
	},
	{
		src = 'https://github.com/hedyhli/outline.nvim',
		cmd = { 'Outline', 'OutlineOpen' },
		config = function()
			require('outline').setup {
				preview_window = {
					auto_preview = true,
					live = true,
				},
			}
		end,
	},
	{ src = 'https://github.com/MunifTanjim/nui.nvim' },
	{
		src = 'https://github.com/Sebastian-Nielsen/better-type-hover',
		ft = { 'typescript', 'typescriptreact' },
	},

	-- {
	-- 	src = 'https://github.com/aikhe/fleur.nvim',
	-- 	priority = 1000,
	-- 	enabled = false,
	-- 	load = true,
	-- 	opts = {
	-- 		transparent = true,
	-- 		styles = {
	-- 			comments = { italic = true },
	-- 			keywords = { bold = true },
	-- 		},
	-- 		plugins = {
	-- 			telescope = true,
	-- 		},
	-- 		-- on_colors = function(c)
	-- 		--   c.accent = '#FF79C6' -- Override accent color
	-- 		-- end,
	-- 	},
	-- 	config = function()
	-- 		vim.cmd [[colorscheme fleur]]
	-- 		vim.cmd [[highlight StatusLine guibg=NONE ctermbg=NONE]]
	-- 	end,
	-- },
}

-- Ghostty: local plugin, lazy on FileType (not a git repo, just add to rtp)
au.autocmd {
	event = 'FileType',
	pattern = 'ghostty',
	callback = function()
		local ghostty_path =
			'/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/'
		if vim.uv.fs_stat(ghostty_path) then
			vim.opt.rtp:prepend(ghostty_path)
		end
	end,
}
