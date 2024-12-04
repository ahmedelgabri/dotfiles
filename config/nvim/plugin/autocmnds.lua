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
		desc = 'Go to the last location when opening a buffer',
		event = 'BufReadPost',
		pattern = '*',
		callback = function(args)
			local row, col = unpack(vim.api.nvim_buf_get_mark(args.buf, '"'))
			local line_count = vim.api.nvim_buf_line_count(args.buf)

			if row > 0 and col <= line_count then
				vim.api.nvim_win_set_cursor(0, { row, col })
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
	{
		event = 'TermOpen',
		pattern = '*',
		command = 'setl nonumber norelativenumber',
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
		event = { 'FileType' },
		desc = 'Disable features in big files',
		pattern = 'bigfile',
		callback = function(args)
			vim.schedule(function()
				vim.bo[args.buf].syntax = vim.filetype.match { buf = args.buf } or ''
			end)

			local bufnr = args.buf

			-- Enable Treesitter folding when not in huge files and when Treesitter
			-- is working.
			if
				vim.bo[bufnr].filetype ~= 'bigfile'
				and pcall(vim.treesitter.start, bufnr)
			then
				vim.api.nvim_buf_call(bufnr, function()
					vim.wo[0][0].foldmethod = 'expr'
					vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
					vim.cmd.normal 'zx'
				end)
			else
				-- Else just fallback to using indentation.
				vim.wo[0][0].foldmethod = 'indent'
			end
		end,
	},
	{
		event = { 'BufDelete', 'BufWipeout' },
		desc = 'Write to ShaDa when deleting/wiping out buffers',
		command = 'wshada',
	},
})
