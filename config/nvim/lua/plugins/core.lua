-- Core/misc plugins
local au = require '_.utils.au'
local hl = require '_.utils.highlight'

-- Eager plugins
vim.pack.add {
	'https://github.com/tpope/vim-repeat',
	'https://github.com/alexghergh/nvim-tmux-navigation',
	{ src = 'https://github.com/saghen/blink.indent', name = 'blink.indent' },
}

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

-- Configure blink.indent
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

vim.schedule(function()
	vim.pack.add { 'https://github.com/wincent/loupe' }
end)

-- nvim-bqf: lazy on FileType qf
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'qf',
	once = true,
	callback = function()
		vim.pack.add {
			{ src = 'https://github.com/junegunn/fzf', name = 'fzf' },
			'https://github.com/kevinhwang91/nvim-bqf',
		}
	end,
})

-- venn.nvim: lazy on key
vim.keymap.set('n', '<leader>v', function()
	vim.pack.add { 'https://github.com/jbyuki/venn.nvim' }

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
end, { noremap = true, desc = 'Enable [V]enn diagramming mode' })

-- vim-kitty: lazy on FileType
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'kitty',
	once = true,
	callback = function()
		vim.pack.add { 'https://github.com/fladson/vim-kitty' }
	end,
})

-- Ghostty: local plugin, lazy on FileType (not a git repo, just add to rtp)
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'ghostty',
	once = true,
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
	local grug_loaded = false
	local function ensure_grug()
		if grug_loaded then
			return
		end
		grug_loaded = true
		vim.pack.add { 'https://github.com/MagicDuck/grug-far.nvim' }

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

	vim.api.nvim_create_user_command('GrugFar', function(cmd_opts)
		pcall(vim.api.nvim_del_user_command, 'GrugFar')
		ensure_grug()
		vim.cmd('GrugFar ' .. (cmd_opts.args or ''))
	end, { nargs = '*' })

	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'grug-far',
		once = true,
		callback = ensure_grug,
	})
end

-- outline.nvim: lazy on cmd
do
	local outline_loaded = false
	local function load_outline()
		if outline_loaded then
			return
		end
		outline_loaded = true
		pcall(vim.api.nvim_del_user_command, 'Outline')
		pcall(vim.api.nvim_del_user_command, 'OutlineOpen')
		vim.pack.add { 'https://github.com/hedyhli/outline.nvim' }
		require('outline').setup {}
	end

	for _, cmd in ipairs { 'Outline', 'OutlineOpen' } do
		vim.api.nvim_create_user_command(cmd, function(cmd_opts)
			load_outline()
			vim.cmd(cmd .. ' ' .. (cmd_opts.args or ''))
		end, { nargs = '*' })
	end
end
