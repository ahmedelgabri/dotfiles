local is_work_machine = function()
	return vim.fn.hostname() == 'rocket'
end

return {
	{
		'https://github.com/github/copilot.vim',
		enabled = is_work_machine(),
		-- build = ':Copilot auth',
		event = 'InsertEnter',
		config = function()
			-- https://github.com/orgs/community/discussions/82729#discussioncomment-8098207
			vim.g.copilot_ignore_node_version = true
			vim.g.copilot_no_tab_map = true
			vim.keymap.set(
				'i',
				'<Plug>(vimrc:copilot-dummy-map)',
				'copilot#Accept("")',
				{ silent = true, expr = true, desc = 'Copilot dummy accept' }
			)

			-- disable copilot outside of work folders and if node is not in $PATH
			if vim.fn.executable 'node' == 0 then
				vim.cmd 'Copilot disable'
			end
		end,
	},
	{
		'https://github.com/supermaven-inc/supermaven-nvim',
		enabled = not is_work_machine(),
		opts = {
			keymaps = {
				accept_suggestion = '<C-g>',
				ignore_filetypes = {
					starter = true,
					dotenv = true,
				},
				-- clear_suggestion = '<C-]>',
				-- accept_word = '<C-j>',
			},
			disable_inline_completion = false, -- disables inline completion for use with cmp
			disable_keymaps = false, -- disables built in keymaps for more manual control
		},
	},
	{ 'https://github.com/duggiefresh/vim-easydir' },
	{
		'https://github.com/stevearc/oil.nvim',
		keys = {
			{
				'-',
				'<CMD>Oil<CR>',
				noremap = true,
				desc = 'Open parent directory',
			},
			{
				'<leader>-',
				function()
					require('oil').toggle_float()
				end,
				noremap = true,
				desc = 'Open parent directory in floating window',
			},
		},
		config = function()
			require('oil').setup {
				-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
				-- Set to false if you still want to use netrw.
				default_file_explorer = false,
				view_options = {
					show_hidden = true,
				},
				delete_to_trash = true,
			}
		end,
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
		event = 'VeryLazy',
		cmd = 'UndotreeToggle',
		keys = {
			{
				'<leader>u',
				vim.cmd.UndotreeToggle,
				noremap = true,
				desc = 'Toggle [U]ndotree',
			},
		},
		init = function()
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
	{ 'https://github.com/wincent/loupe' },
	{
		'https://github.com/christoomey/vim-tmux-navigator',
		lazy = false,
		config = function()
			vim.g.tmux_navigator_disable_when_zoomed = 1
		end,
	},
	{ 'https://github.com/kevinhwang91/nvim-bqf', ft = 'qf' },
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
		'https://github.com/folke/zen-mode.nvim',
		cmd = { 'ZenMode' },
		keys = {
			{
				'<leader>z',
				vim.cmd.ZenMode,
				noremap = true,
				desc = 'Toggle buffer [z]en/[z]oom mode',
			},
		},
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
}
