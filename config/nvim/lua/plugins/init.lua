local enable_ai = function()
	local current_dir = vim.fn.getcwd()

	-- if git repo is not under ~/Sites/work, do not allow AI
	local work_path = os.getenv 'WORK' or os.getenv 'HOME' .. '/Sites/work'
	local is_work_code = string.find(current_dir, work_path) == 1

	return is_work_code
end

return {
	{
		'https://github.com/github/copilot.vim',
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
			if not enable_ai() or vim.fn.executable 'node' == 0 then
				vim.cmd 'Copilot disable'
			end
		end,
	},
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
		init = function()
			vim.g.skip_ts_context_commentstring_module = true
		end,
		opts = function()
			return {
				pre_hook = function()
					return vim.bo.commentstring
				end,
			}
		end,
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
