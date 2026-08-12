local pack = require '_.pack'

vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'

pack.add {
	{
		src = 'https://github.com/ibhagwan/fzf-lua',
		event = { 'UIEnter' },
		config = function()
			local actions = require 'fzf-lua.actions'
			local defaults = require 'fzf-lua.defaults'
			local previewers = require 'fzf-lua.previewer'
			local utils = require '_.utils'

			-- Keep this in sync with `git config alias.l`.
			local git_log_args =
				[[--color=always --graph --pretty=format:"%C(blue)%h %Creset- %C(green)%>(12)(%cr) %Creset%s - %C(cyan)%aN %C(magenta)%d" --date=auto:human]]

			local function log_cmd(extra)
				return 'git log ' .. git_log_args .. (extra and (' ' .. extra) or '')
			end

			require('fzf-lua').setup {
				defaults = {
					-- Git icons are very slow in large codea bases and not very useful
					-- https://github.com/ibhagwan/fzf-lua/wiki#how-do-i-get-maximum-performance-out-of-fzf-lua
					git_icons = false,
				},
				file_icon_padding = ' ',
				file_icons = 'mini',
				winopts = {
					border = utils.get_border(),
					preview = {
						default = 'previewer',
						border = utils.get_border(),
						winopts = {
							number = false,
							cursorline = true,
						},
					},
				},
				previewers = {
					previewer = {
						cmd = 'COLORTERM=truecolor previewer',
						_ctor = previewers.fzf.cmd,
					},
				},
				fzf_opts = {
					['--pointer'] = '▶',
					['--marker'] = '✓ ',
					['--no-scrollbar'] = true,
					['--info'] = 'inline-right',
					['--walker-skip'] = '.git,node_modules',
					-- Run fzf in a tmux popup like the shell widgets; fzf-lua
					-- ignores this outside tmux and falls back to the float.
					-- fzf renamed the flag to --popup (--tmux is an alias) but
					-- this key is fzf-lua's API: its popup-mode detection only
					-- matches "--tmux", so don't "modernize" it.
					['--tmux'] = 'center,85%,85%',
				},
				keymap = {
					builtin = {
						['?'] = 'toggle-preview',
					},
				},
				oldfiles = {
					include_current_session = true,
					stat_file = true,
				},
				buffers = {
					_fzf_nth_devicons = true,
					-- The provider defaults this to "{1}" which, combined with the
					-- nbsp delimiter from `_fzf_nth_devicons`, sends the "[bufnr]"
					-- column instead of the file path to the shell previewer.
					field_index_expr = '{}',
					-- With the nbsp delimiter the default "{2}" is the flags column;
					-- the line number is the last field.
					line_field_index = '{-1}',
				},
				files = {
					cwd_prompt = false,
					fd_opts = vim.env.FZF_DEFAULT_COMMAND and nil
						or defaults.defaults.files.fd_opts,
					cmd = vim.env.FZF_DEFAULT_COMMAND ~= nil
							and vim.env.FZF_DEFAULT_COMMAND
						or defaults.defaults.files.cmd,
					no_ignore = true,
					hidden = true,
					follow = true,
					line_query = true,
					_fzf_nth_devicons = true,
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
					cmd = log_cmd(),
				},
				bcommits = {
					cmd = log_cmd '{file}',
				},
			}

			vim.keymap.set('n', '<leader><leader>', function()
				require('fzf-lua').files {}
			end, { silent = true, desc = 'Search Files' })

			vim.keymap.set('n', '<leader>b', function()
				require('fzf-lua').buffers {}
			end, { silent = true, desc = 'Search [B]uffers' })

			vim.keymap.set('n', '<leader>h', function()
				require('fzf-lua').help_tags {}
			end, { silent = true, desc = 'Search [H]elp' })

			vim.keymap.set('n', '<Leader>o', function()
				require('fzf-lua').oldfiles {}
			end, { silent = true, desc = 'Search [O]ldfiles' })

			vim.keymap.set('n', '<Leader>\\', function()
				require('fzf-lua').live_grep { exec_empty_query = true }
			end, { silent = true, desc = 'grep project' })

			vim.keymap.set('n', '<leader>ta', function()
				require('fzf-lua').grep_project {
					winopts = { title = ' Tasks ' },
					search = '^\\s*- \\[ \\]',
					no_esc = true,
					no_ignore = true,
					hidden = true,
				}
			end, { desc = 'Search for incomplete t[a]sks' })

			vim.keymap.set('n', '<leader>to', function()
				require('fzf-lua').grep_project {
					winopts = { title = ' TODOs ' },
					search = [[^\s*?(//|#|--|%|;|/\*)\s*@?(todo|note|hack|bug|fixme|fix|warn|xxx):?\b]],
					no_esc = true,
					no_ignore = true,
					hidden = true,
				}
			end, { desc = 'Search for t[o]dos' })

			vim.keymap.set('n', 'z=', function()
				require('fzf-lua').spell_suggest {}
			end, { silent = true, desc = 'Spelling Suggestions' })
		end,
	},
}
