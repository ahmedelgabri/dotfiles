return {
	{ 'https://github.com/duggiefresh/vim-easydir' },
	{
		'https://github.com/ojroques/vim-oscyank',
		event = { 'TextYankPost *' },
		config = function()
			local au = require '_.utils.au'

			au.augroup('__oscyank__', {
				{
					event = { 'TextYankPost' },
					pattern = '*',
					callback = function()
						if vim.v.event.operator == 'y' and vim.v.event.regname == '' then
							vim.cmd [[OSCYankRegister "]]
						end
					end,
				},
			})
		end,
	},
	{
		'https://github.com/kyazdani42/nvim-tree.lua',
		keys = {
			{
				'--',
				':NvimTreeFindFile<CR>',
				{ silent = true },
				desc = 'Open Nvimtree',
			},
		},
		opts = {
			view = {
				side = 'right',
			},
			update_focused_file = {
				enable = true,
			},
			git = {
				ignore = false,
			},
			renderer = {
				indent_markers = {
					enable = false,
				},
				-- Normally README.md gets highlighted by default, which is a bit distracting.
				special_files = {},
				icons = {
					show = {
						git = true,
						file = false,
						folder = false,
						folder_arrow = false,
					},
				},
			},
			actions = {
				open_file = {
					quit_on_open = true,
					resize_window = true,
					window_picker = {
						enable = false,
					},
				},
			},
			-- vim-fugitive :GBrowse depends on netrw & this has to be set as early as possible
			-- maybe switch to https://github.com/ruifm/gitlinker.nvim?
			-- I only use fugitive for GBrowse 99% of the time & git branch in the statusline
			disable_netrw = false,
		},
	},
	{
		'https://github.com/folke/which-key.nvim',
		event = 'VeryLazy',
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			window = {
				border = 'single',
			},
		},
	},
	{
		'https://github.com/mbbill/undotree',
		cmd = 'UndotreeToggle',
		keys = {
			{
				'<leader>u',
				vim.cmd.UndotreeToggle,
				silent = true,
				noremap = true,
				desc = 'Toggle [U]ndotree',
			},
		},
		config = function()
			vim.g.undotree_WindowLayout = 2
			vim.g.undotree_SplitWidth = 50
			vim.g.undotree_SetFocusWhenToggle = 1
		end,
	},
	{
		'https://github.com/tpope/tpope-vim-abolish',
		cmd = { 'Abolish', 'S', 'Subvert' },
	},
	{
		'https://github.com/tpope/vim-eunuch',
		cmd = { 'Delete' },
		keys = {
			{
				'<leader>m',
				':Move <C-R>=expand("%")<cr>',
				{ remap = true },
				desc = '[M]ove file',
			},
		},
	},
	{ 'https://github.com/tpope/vim-repeat' },
	{
		'https://github.com/nullchilly/fsread.nvim',
		cmd = { 'FSRead', 'FSToggle', 'FSClear' },
	},
	{
		'https://github.com/numToStr/Comment.nvim',
		dependencies = {
			'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
		},
		keys = {
			{ 'gc', mode = { 'n', 'x' } },
			{ 'gb', mode = { 'n', 'x' } },
		},
		opts = {
			ignore = '^$', -- don't comment empty lines
			---@param ctx Ctx
			pre_hook = function(ctx)
				-- Only calculate commentstring for tsx filetypes
				if
					vim.tbl_contains({
						'typescriptreact',
						'typescript.tsx',
						'javascriptreact',
						'javascript.jsx',
					}, vim.bo.filetype)
				then
					local U = require 'Comment.utils'

					-- Detemine whether to use linewise or blockwise commentstring
					local type = ctx.ctype == U.ctype.line and '__default'
						or '__multiline'

					-- Determine the location where to calculate commentstring from
					local location = nil
					if ctx.ctype == U.ctype.block then
						location =
							require('ts_context_commentstring.utils').get_cursor_location()
					elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
						location =
							require('ts_context_commentstring.utils').get_visual_start_location()
					end

					return require('ts_context_commentstring.internal').calculate_commentstring {
						key = type,
						location = location,
					}
				end
			end,
		},
	},
	{ 'https://github.com/wincent/loupe' },
	{
		'https://github.com/simrat39/symbols-outline.nvim',
		cmd = 'SymbolsOutline',
	},
	{
		'https://github.com/christoomey/vim-tmux-navigator',
		lazy = false,
		config = function()
			vim.g.tmux_navigator_disable_when_zoomed = 1
		end,
	},
	{ 'https://github.com/kevinhwang91/nvim-bqf' },
	{
		'https://github.com/rgroli/other.nvim',
		cmd = { 'Other', 'OtherSplit', 'OtherVSplit' },
		config = function()
			local ok, local_config = pcall(require, '_.config.other-local')

			require('other-nvim').setup {
				-- These chars needs to be escaped inside pattern only.
				-- ( ) . % + - * ? [ ^ $
				-- Escaping is done with prepending a % to it
				-- https://github.com/rgroli/other.nvim/issues/4#issuecomment-1108372317
				mappings = vim.tbl_extend('force', {}, ok and local_config or {}),
			}
		end,
	},
	-- Syntax {{{
	{ 'https://github.com/jez/vim-github-hub' },
	{
		'https://github.com/jxnblk/vim-mdx-js',
		ft = { 'mdx', 'markdown.mdx' },
	},
	-- }}}

	-- Git {{{
	{
		'https://github.com/akinsho/git-conflict.nvim',
		opts = {},
	},
	{
		'https://github.com/sindrets/diffview.nvim',
		dependencies = { { 'https://github.com/nvim-lua/plenary.nvim' } },
		cmd = { 'DiffviewOpen' },
		opts = {
			use_icons = false,
		},
	},
	-- }}}

	{
		'https://github.com/edluffy/hologram.nvim',
		ft = { 'markdown', 'txt' },
		config = function()
			require('hologram').setup {
				auto_display = true, -- WIP automatic markdown image display, may be prone to breaking
			}
		end,
	},

	{
		'https://github.com/folke/zen-mode.nvim',
		cmd = { 'ZenMode' },
		opts = {
			on_close = function()
				local is_last_buffer = #vim.fn.filter(
					vim.fn.range(1, vim.fn.bufnr '$'),
					'buflisted(v:val)'
				) == 1

				if vim.api.nvim_buf_get_var(0, 'quitting') == 1 and is_last_buffer then
					if vim.api.nvim_buf_get_var(0, 'quitting_bang') == 1 then
						vim.cmd 'qa!'
					else
						vim.cmd 'qa'
					end
				end
			end,

			on_open = function()
				vim.api.nvim_buf_set_var(0, 'quitting', 0)
				vim.api.nvim_buf_set_var(0, 'quitting_bang', 0)
				vim.cmd [[autocmd! QuitPre <buffer> let b:quitting = 1]]
				vim.cmd 'cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!'
			end,

			plugins = {
				options = {
					showbreak = '',
					showmode = false,
				},
				tmux = {
					enabled = true,
				},
			},
			window = {
				options = {
					cursorline = false,
					number = false,
					relativenumber = false,
				},
			},
		},
	},
	-- Themes, UI & eye candy {{{
	-- Will load from local machine on personal, from git otherwise.
	-- Check lazy.nvim config.dev
	{ 'ahmedelgabri/vim-colors-plain', lazy = true, dev = true },
	-- }}}
}
