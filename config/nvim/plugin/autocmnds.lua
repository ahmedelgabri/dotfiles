local au = require '_.utils.au'
local cmds = require '_.autocmds'

au.augroup('__myautocmds__', {
	{
		event = 'VimResized',
		desc = 'Make splits equal in size',
		pattern = '*',
		command = 'wincmd =',
	},
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
		event = { 'BufWritePost', 'BufLeave', 'WinLeave' },
		pattern = '?*',
		callback = cmds.mkview,
	},
	{
		event = 'BufWinEnter',
		pattern = '?*',
		callback = cmds.loadview,
	},
	{
		event = 'FileType',
		pattern = {
			'diff',
			'fzf',
			'grepper',
			'help',
			'man',
			'netrw',
			'preview',
			'qf',
			'query',
			'scratch',
			'taskedit',
			'grug-far',
		},
		desc = 'Close with <q>',
		callback = function(args)
			vim.keymap.set(
				'n',
				'q',
				-- (
				-- 	(vim.wo.diff == true or vim.bo.filetype == 'man') and ':qa!'
				-- 	or (vim.bo.filetype == 'qf') and ':cclose'
				-- 	or (vim.bo.buftype == 'nofile') and ':q'
				-- 	or ':q'
				-- ) .. '<cr>',
				'<cmd>quit<cr>',
				{ buffer = args.buf, desc = '[Q]uit on q' }
			)
		end,
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
			vim.hl.on_yank {
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
	{ event = 'TermOpen', pattern = 'term://*', command = 'startinsert' },
	{ event = 'TermClose', pattern = 'term://*', command = 'stopinsert' },

	-- Copied from https://github.com/duggiefresh/vim-easydir/blob/2efbed9e24438f626971a526d19af719b89e8040/plugin/easydir.vim
	{
		event = { 'BufWritePre', 'FileWritePre' },
		desc = [[Create required folders if they don't exist]],
		pattern = '*',
		callback = function()
			local directory = vim.fn.expand '<afile>:p:h'

			if not directory:match '^%w+:' and vim.fn.isdirectory(directory) == 0 then
				vim.fn.mkdir(directory, 'p')
			end
		end,
	},
	{
		event = { 'BufDelete', 'BufWipeout' },
		desc = 'Write to ShaDa when deleting/wiping out buffers',
		command = 'wshada',
	},
})
