-- Core/misc plugins
local au = require '_.utils.au'
local hl = require '_.utils.highlight'

Pack.add({
	'https://github.com/tpope/vim-repeat',
	'https://github.com/alexghergh/nvim-tmux-navigation',
	{
		src = 'https://github.com/saghen/blink.indent',
		name = 'blink.indent',
	},
	{ src = 'https://github.com/wincent/loupe' },
	{
		src = 'https://github.com/junegunn/fzf',
		name = 'fzf',
	},
	{ src = 'https://github.com/kevinhwang91/nvim-bqf' },
	{ src = 'https://github.com/jbyuki/venn.nvim' },
	{ src = 'https://github.com/fladson/vim-kitty' },
	{ src = 'https://github.com/MagicDuck/grug-far.nvim' },
	{ src = 'https://github.com/hedyhli/outline.nvim' },
	{ src = 'https://github.com/MunifTanjim/nui.nvim' },

	'https://github.com/Sebastian-Nielsen/better-type-hover',

	-- {
	-- 	'https://github.com/aikhe/fleur.nvim',
	-- 	priority = 1000,
	-- 	enabled = false,
	-- 	lazy = false,
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
}, { load = false })

au.autocmd {
	event = 'FileType',
	pattern = { 'typescript', 'typescriptreact' },
	callback = function()
		Pack.load 'better-type-hover'
	end,
}

if vim.env.TMUX then
	Pack.load 'nvim-tmux-navigation'

	require('nvim-tmux-navigation').setup {
		disable_when_zoomed = true,
		keybindings = {
			left = '<C-h>',
			down = '<C-j>',
			up = '<C-k>',
			right = '<C-l>',
		},
	}
end

vim.schedule(function()
	Pack.load 'blink.indent'

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
end)

-- Loupe: load after startup (was event = 'VeryLazy')
vim.g.LoupeClearHighlightMap = 0
-- Not needed in Neovim (see `:help hl-CurSearch`).
vim.g.LoupeHighlightGroup = ''

local function set_up_loupe_highlight()
	hl.group('QuickFixLine', { link = 'PmenuSel' })
	vim.cmd 'highlight! clear Search'
	hl.group('Search', { link = 'Underlined' })
end

local loupe_group = vim.api.nvim_create_augroup('__myloupe__', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = loupe_group,
	pattern = '*',
	callback = set_up_loupe_highlight,
})

set_up_loupe_highlight()
vim.schedule(function()
	Pack.load 'loupe'
end)

-- nvim-bqf: lazy on FileType qf
au.autocmd {
	event = 'FileType',
	pattern = 'qf',
	callback = function()
		Pack.load { 'fzf', 'nvim-bqf' }
	end,
}

-- venn.nvim: lazy on key
Pack.keys({
	{
		lhs = '<leader>v',
		opts = { noremap = true, desc = 'Enable [V]enn diagramming mode' },
		rhs = function()
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
		end,
	},
}, function()
	return Pack.load 'venn.nvim'
end)

-- vim-kitty: lazy on FileType
au.autocmd {
	event = 'FileType',
	pattern = 'kitty',
	callback = function()
		Pack.load 'vim-kitty'
	end,
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

local function setup_grug_far()
	Pack.load 'grug-far.nvim'

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
end

Pack.cmd('GrugFar', setup_grug_far)
au.autocmd {
	event = 'FileType',
	pattern = 'grug-far',
	callback = setup_grug_far,
}

Pack.cmd({ 'Outline', 'OutlineOpen' }, function()
	Pack.load 'outline.nvim'
	require('outline').setup {}
end)
