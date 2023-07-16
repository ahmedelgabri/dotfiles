return {
	'https://github.com/junegunn/fzf.vim',
	-- I have the bin globally, so don't build, and just grab plugin directory
	dependencies = { { 'https://github.com/junegunn/fzf' } },
	keys = {
		{
			'<leader><leader>',
			vim.cmd.Files,
			{ silent = true },
			desc = 'Search Files',
		},
		{
			'<Leader>b',
			vim.cmd.Buffers,
			{ silent = true },
			desc = 'Search [B]uffers',
		},
		{
			'<Leader>h',
			vim.cmd.Helptags,
			{ silent = true },
			desc = 'Search [H]elp',
		},
		{
			'<Leader>o',
			vim.cmd.History,
			{ silent = true },
			desc = 'Search [O]ldfiles',
		},
	},
	config = function()
		if vim.fn.exists ':FZF' == 0 then
			return
		end

		local au = require '_.utils.au'

		if vim.env.FZF_CTRL_T_OPTS ~= nil then
			vim.g.fzf_files_options = vim.env.FZF_CTRL_T_OPTS
		end

		if vim.env.VIM_FZF_LOG ~= nil then
			vim.g.fzf_commits_log_options = vim.env.VIM_FZF_LOG
		end

		vim.g.fzf_layout =
			{ window = { width = 0.9, height = 0.8, relative = false } }
		vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'
		vim.g.fzf_buffers_jump = 1
		vim.g.fzf_tags_command = 'ctags -R'
		vim.g.fzf_preview_window = 'right:border-left'
		vim.g.fzf_colors = {
			-- fg = { 'fg', 'Normal' },
			-- bg = { 'bg', 'Normal' },
			-- ['preview-bg'] = { 'bg', 'NormalFloat' },
			-- hl = { 'fg', 'Comment' },
			-- ['fg+'] = { 'fg', 'CursorLine', 'CursorColumn', 'Normal' },
			-- ['bg+'] = { 'bg', 'CursorLine', 'CursorColumn' },
			-- ['hl+'] = { 'fg', 'Statement' },
			-- info = { 'fg', 'PreProc' },
			border = { 'fg', 'Ignore' },
			-- prompt = { 'fg', 'Conditional' },
			-- pointer = { 'fg', 'Exception' },
			-- marker = { 'fg', 'Keyword' },
			-- spinner = { 'fg', 'Label' },
			-- header = { 'fg', 'Comment' },
		}

		vim.keymap.set(
			{ 'i' },
			'<c-x><c-k>',
			'<plug>(fzf-complete-word)',
			{ remap = true }
		)
		vim.keymap.set(
			{ 'i' },
			'<c-x><c-f>',
			'<plug>(fzf-complete-path)',
			{ remap = true }
		)
		vim.keymap.set(
			{ 'i' },
			'<c-x><c-j>',
			'<plug>(fzf-complete-file-ag)',
			{ remap = true }
		)
		vim.keymap.set(
			{ 'i' },
			'<c-x><c-l>',
			'<plug>(fzf-complete-line)',
			{ remap = true }
		)

		-- Override Files to show resposnive UI depending on the window width
		vim.api.nvim_create_user_command('Files', function(o)
			vim.fn['fzf#vim#files'](
				o.args,
				vim.fn['fzf#vim#with_preview'] {
					options = {
						'--preview-window',
						'right:border-left,<70(down:border-top)',
						'--border-label',
						vim.fn.fnamemodify(vim.env.PWD, ':~'),
						'--border-label-pos',
						3,
						'--prompt',
						'» ',
					},
				},
				o.bang
			)
		end, { bang = true, nargs = '?', complete = 'dir' })

		au.augroup('__my_fzf__', {
			{
				event = 'User',
				pattern = 'FzfStatusLine',
				callback = function()
					vim.opt_local.statusline = table.concat(
						{ '%4*', 'fzf', '%6*', 'V: ctrl-v', 'H: ctrl-x', 'Tab: ctrl-t' },
						' '
					)
				end,
			},
		})

		function FzfSpellSink(word)
			vim.fn.execute('normal! "_ciw' .. word)
		end

		function FzfSpell()
			local suggestions = vim.fn.spellsuggest(vim.fn.expand '<cword>')
			return vim.fn['fzf#run'] {
				source = suggestions,
				sink = FzfSpellSink,
				down = 25,
			}
		end

		-- vim.keymap.set(
		-- 	{ 'n' },
		-- 	'z=',
		-- 	FzfSpell,
		-- 	{ silent = true, desc = 'Spell check' }
		-- )

		-- https://github.com/junegunn/fzf.vim/issues/907#issuecomment-554699400
		local function ripgrepFzf(query, fullscreen)
			local command_fmt =
				'rg --column --line-number --no-heading --color=always -g "!*.lock" -g "!*lock.json" --smart-case %s || true'
			local initial_command =
				string.format(command_fmt, vim.fn.shellescape(query))
			local reload_command = string.format(command_fmt, '{q}')
			local spec = {
				options = {
					'--phony',
					'--query',
					query,
					'--bind',
					'change:reload:' .. reload_command,
				},
			}
			vim.fn['fzf#vim#grep'](
				initial_command,
				1,
				vim.fn['fzf#vim#with_preview'](spec),
				fullscreen
			)
		end

		vim.api.nvim_create_user_command('RG', function(o)
			ripgrepFzf(o.args, o.bang)
		end, { bang = true, nargs = '*' })

		vim.keymap.set(
			{ 'n' },
			[[<leader>\]],
			[[:RG<CR>]],
			{ desc = 'Search using ripgrep' }
		)
	end,
}
