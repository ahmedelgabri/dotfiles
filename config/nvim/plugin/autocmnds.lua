local au = require '_.utils.au'
local cmds = require '_.autocmds'

au.augroup('__myautocmds__', {
	-- Automatically make splits equal in size
	{ event = 'VimResized', pattern = '*', command = 'wincmd =' },
	-- Disable paste mode on leaving insert mode.
	-- See https://github.com/neovim/neovim/issues/7994
	{ event = 'InsertLeave', pattern = '*', command = 'set nopaste' },
	{
		event = 'BufWritePost',
		pattern = '.envrc',
		callback = function()
			if vim.fn.executable 'direnv' then
				vim.cmd [[silent !direnv allow %]]
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
			}
		end,
	},
	{
		event = 'BufWritePost',
		pattern = '*/spell/*.add',
		command = 'silent! :mkspell! %',
	},
	{
		event = { 'BufRead', 'BufNewFile' },
		pattern = 'package.json',
		callback = function()
			vim.keymap.set({ 'n' }, 'gx', function()
				local line = vim.fn.getline '.'
				local _, _, package, _ = string.find(line, [[^%s*"(.*)":%s*"(.*)"]])

				if package then
					local url = 'https://www.npmjs.com/package/' .. package
					vim.ui.open(url)
				end
			end, { buffer = true, silent = true, desc = '[G]o to [p]ackage' })
		end,
	},
	{
		event = 'InsertLeave',
		pattern = '*',
		command = [[execute 'normal! mI']],
		desc = 'global mark I for last edit',
	},
	{
		-- https://github.com/neovim/neovim/pull/28176#issuecomment-2051944146
		desc = 'Force commentstring to include spaces',
		event = 'FileType',
		pattern = '*',
		callback = function(event)
			local cs = vim.bo[event.buf].commentstring
			vim.bo[event.buf].commentstring = cs:gsub('(%S)%%s', '%1 %%s')
				:gsub('%%s(%S)', '%%s %1')
		end,
	},
})
