local au = require '_.utils.au'
local cmds = require '_.autocmds'
local hl = require '_.utils.highlight'
local utils = require '_.utils'

au.augroup('__myautocmds__', {
	-- Automatically make splits equal in size
	{ event = 'VimResized', pattern = '*', command = 'wincmd =' },
	-- Disable paste mode on leaving insert mode.
	-- See https://github.com/neovim/neovim/issues/7994
	{ event = 'InsertLeave', pattern = '*', command = 'set nopaste' },
	{
		event = { 'BufEnter', 'BufWinEnter', 'BufRead', 'BufNewFile' },
		pattern = 'bookmarks.{md,txt}',
		callback = function()
			hl.group('mkdLink', { link = 'Normal' })
			vim.cmd [[set concealcursor-=n]]
		end,
	},

	{
		event = 'BufWritePost',
		pattern = '*/spell/*.add',
		callback = function()
			vim.cmd [[ silent! :mkspell! %]]
		end,
	},

	{
		event = 'BufWritePost',
		pattern = '.envrc',
		callback = function()
			if vim.fn.executable 'direnv' then
				vim.cmd [[ silent !direnv allow %]]
			end
		end,
	},

	{
		event = 'BufReadPre',
		pattern = '*',
		callback = cmds.disable_heavy_plugins,
	},
	{
		desc = 'Open file at the last position it was edited earlier',
		event = 'BufReadPost',
		pattern = '*',
		callback = function()
			local row, col = unpack(vim.api.nvim_buf_get_mark(0, '"'))

			if { row, col } ~= { 0, 0 } then
				vim.api.nvim_win_set_cursor(0, { row, 0 })
			end
		end,
	},
	{
		event = { 'BufWritePost', 'BufLeave', 'WinLeave' },
		pattern = '?*',
		callback = cmds.mkview,
	},
	{
		event = 'BufWinEnter',
		pattern = '?*',
		callback = cmds.loadview,
	},

	-- Close preview buffer with q
	{
		event = 'FileType',
		pattern = '*',
		callback = cmds.quit_on_q,
	},

	-- Project specific override
	{
		event = { 'BufRead', 'BufNewFile' },
		pattern = '*',
		callback = cmds.source_project_config,
	},
	{
		event = 'DirChanged',
		pattern = '*',
		callback = cmds.source_project_config,
	},

	{
		event = 'TextYankPost',
		pattern = '*',
		callback = function()
			vim.highlight.on_yank {
				higroup = 'IncSearch',
				timeout = 200,
				on_visual = false,
			}
		end,
	},

	{
		event = { 'BufEnter', 'WinEnter' },
		pattern = { '*/node_modules/*', '*.min.*' },
		command = ':LspStop',
	},
	{
		event = 'BufLeave',
		pattern = { '*/node_modules/*', '*.min.*' },
		command = ':LspStart',
	},

	{
		event = 'BufWritePost',
		pattern = '*/spell/*.add',
		command = 'silent! :mkspell! %',
	},
	{ event = 'BufWritePost', pattern = '*', command = 'silent! FormatWrite' },
	{
		event = { 'BufRead', 'BufNewFile' },
		pattern = 'package.json',
		callback = function()
			vim.keymap.set({ 'n' }, '<leader>gx', function()
				utils.package_json_gx()
			end, { buffer = true, silent = true, desc = '[G]o to [p]ackage' })
		end,
	},
	{
		event = 'InsertLeave',
		pattern = '*',
		command = [[execute 'normal! mI']],
		desc = 'global mark I for last edit',
	},
})
