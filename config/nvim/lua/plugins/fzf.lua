return {
	{
		'https://github.com/ibhagwan/fzf-lua',
		ft = { 'markdown' },
		keys = {
			{
				'<leader><leader>',
				function()
					require('fzf-lua').files {}
				end,
				{ silent = true },
				desc = 'Search Files',
			},
			{
				'<leader>b',
				function()
					require('fzf-lua').buffers {}
				end,
				{ silent = true },
				desc = 'Search [B]uffers',
			},
			{
				'<leader>h',
				function()
					require('fzf-lua').help_tags {}
				end,
				{ silent = true },
				desc = 'Search [H]elp',
			},
			{
				'<Leader>o',
				function()
					require('fzf-lua').oldfiles {}
				end,
				{ silent = true },
				desc = 'Search [O]ldfiles',
			},
			{
				'<Leader>\\',
				function()
					require('fzf-lua').live_grep_glob { exec_empty_query = true }
				end,
				{ silent = true },
				desc = 'grep project',
			},
			{
				-- Overrides default z=
				'z=',
				function()
					require('fzf-lua').spell_suggest {}
				end,
				{ silent = true },
				desc = 'Spelling Suggestions',
			},
		},
		init = function()
			vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'

			-- Replaces vim.ui.select
			-- https://github.com/ibhagwan/fzf-lua/wiki#automatic-sizing-of-heightwidth-of-vimuiselect
			require('fzf-lua').register_ui_select(function(_, items)
				local min_h, max_h = 0.15, 0.70
				local h = (#items + 4) / vim.o.lines
				if h < min_h then
					h = min_h
				elseif h > max_h then
					h = max_h
				end
				return { winopts = { height = h, width = 0.60, row = 0.40 } }
			end)
		end,
		opts = function(_, opts)
			local utils = require '_.utils'
			local actions = require 'fzf-lua.actions'
			local defaults = require 'fzf-lua.defaults'
			local function log_cmd(fallback, extra)
				return vim.env.VIM_FZF_LOG
						and 'git log ' .. vim.env.VIM_FZF_LOG .. ' ' .. (extra or '')
					or fallback
			end

			return vim.tbl_deep_extend('force', opts or {}, {
				defaults = {
					-- Git icons are very slow in large codea bases and not very useful
					-- https://github.com/ibhagwan/fzf-lua/wiki#how-do-i-get-maximum-performance-out-of-fzf-lua
					git_icons = false,
				},
				file_icon_padding = ' ',
				file_icons = 'mini',
				winopts = {
					border = utils.get_border(),
					width = 0.9,
					height = 0.8,
					preview = {
						border = utils.get_border(),
						winopts = {
							number = false,
							cursorline = true,
						},
					},
					on_create = function()
						-- disable indent plugins
						vim.b.miniindentscope_disable = true
						vim.b.snacks_indent = true
					end,
				},
				fzf_opts = {
					['--pointer'] = '▶',
					['--marker'] = '✓ ',
					['--no-scrollbar'] = true,
				},
				keymap = {
					builtin = {
						['?'] = 'toggle-preview',
					},
				},
				oldfiles = {
					include_current_session = true,
					stat_file = true, -- verify files exist on disk
				},
				files = {
					cwd_prompt = false,
					fd_opts = vim.env.FZF_DEFAULT_COMMAND and nil
						or defaults.defaults.files.fd_opts,
					cmd = vim.env.FZF_DEFAULT_COMMAND ~= nil
							and vim.env.FZF_DEFAULT_COMMAND
						or defaults.defaults.files.cmd,
					actions = {
						['ctrl-g'] = false,
						['default'] = actions.file_edit,
					},
				},
				grep = {
					rg_glob = true,
					actions = {
						['ctrl-q'] = {
							fn = actions.file_edit_or_qf,
							prefix = 'select-all+',
						},
					},
				},
				commits = {
					cmd = log_cmd(defaults.defaults.git.commits.cmd),
				},
				bcommits = {
					cmd = log_cmd(defaults.defaults.git.bcommits.cmd, '{file}'),
				},
			})
		end,
	},
}
