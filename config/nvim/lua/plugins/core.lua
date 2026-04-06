-- Core/misc plugins
local au = require '_.utils.au'
local hl = require '_.utils.highlight'
local pack = require 'plugins.pack'

-- Configure tmux navigation
require('nvim-tmux-navigation').setup {
	disable_when_zoomed = true,
	keybindings = {
		left = '<C-h>',
		down = '<C-j>',
		up = '<C-k>',
		right = '<C-l>',
	},
}

local function ensure_blink_indent()
	return pack.setup('blink.indent', function()
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
end

pack.later(ensure_blink_indent)

-- Loupe: load after startup (was event = 'VeryLazy')
vim.g.LoupeClearHighlightMap = 0
-- Not needed in Neovim (see `:help hl-CurSearch`).
vim.g.LoupeHighlightGroup = ''

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

pack.later(function()
	pack.load 'loupe'
end)

-- nvim-bqf: lazy on FileType qf
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'qf',
	callback = function()
		pack.load { 'fzf', 'nvim-bqf' }
	end,
})

-- venn.nvim: lazy on key
vim.keymap.set('n', '<leader>v', function()
	pack.load 'venn.nvim'

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

-- vim-kitty: lazy on FileType
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'kitty',
	callback = function()
		pack.load 'vim-kitty'
	end,
})

-- Ghostty: local plugin, lazy on FileType (not a git repo, just add to rtp)
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'ghostty',
	callback = function()
		local ghostty_path =
			'/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/'
		if vim.uv.fs_stat(ghostty_path) then
			vim.opt.rtp:prepend(ghostty_path)
		end
	end,
})

-- grug-far.nvim: lazy on cmd and FileType
do
	local function ensure_grug()
		return pack.setup('grug-far.nvim', function()
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
		end)
	end

	pack.lazy_cmd('GrugFar', ensure_grug)

	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'grug-far',
		callback = ensure_grug,
	})
end

-- outline.nvim: lazy on cmd
do
	local function ensure_outline()
		return pack.setup('outline.nvim', function()
			require('outline').setup {}
		end)
	end

	pack.lazy_cmd({ 'Outline', 'OutlineOpen' }, ensure_outline)
end
