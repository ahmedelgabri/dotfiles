---@diagnostic disable: missing-fields

local pack = require '_.pack'

pack.add {
	{
		src = 'https://github.com/folke/snacks.nvim',
		config = function()
			-- Init code (runs immediately)
			vim.g.snacks_animate = false

			vim.schedule(function()
				-- Setup some globals for debugging (lazy-loaded)
				-- selene: allow(global_usage)
				_G.P = function(...)
					Snacks.debug.inspect(...)
				end
				-- selene: allow(global_usage)
				_G.bt = function()
					Snacks.debug.backtrace()
				end
			end)

			vim.api.nvim_create_user_command('Zen', function()
				require('snacks').zen()
			end, { desc = 'Toggle Zen Mode' })

			vim.api.nvim_create_autocmd('User', {
				pattern = 'OilActionsPost',
				callback = function(event)
					if event.data.actions.type == 'move' then
						require('snacks').rename.on_rename_file(
							event.data.actions.src_url,
							event.data.actions.dest_url
						)
					end
				end,
			})

			-- Key mappings
			vim.keymap.set('n', '<leader>.', function()
				vim.ui.input({
					prompt = 'Enter filetype for the scratch buffer: ',
					default = 'markdown',
					completion = 'filetype',
				}, function(ft)
					require('snacks').scratch.open {
						ft = ft,
						win = {
							width = 200,
							height = 100,
							title = 'Scratch Buffer',
						},
					}
				end)
			end, { desc = 'Toggle Scratch Buffer' })

			vim.keymap.set('n', '<leader>S', function()
				require('snacks').scratch.select()
			end, { desc = 'Select Scratch Buffer' })

			vim.keymap.set('n', '<localleader>t', function()
				local git_root = vim.fs.root(0, '.git')
				if git_root then
					local file = git_root .. '/todo.md'
					require('snacks').scratch.open {
						ft = 'markdown',
						file = file,
					}
				end
			end, { desc = 'Toggle Scratch Todo' })

			vim.keymap.set('n', '<leader>z', function()
				require('snacks').zen.zoom()
			end, { silent = true, desc = 'Toggle buffer [z]oom mode' })

			-- Configure snacks
			require('snacks').setup {
				quickfile = { enabled = false },
				scroll = { enabled = false },
				statuscolumn = { enabled = false },
				indent = { enabled = false },
				input = { enabled = false },
				bigfile = { enabled = false },
				picker = { enabled = false },
				image = {
					doc = {
						float = true,
						inline = false,
					},
				},
			}
		end,
	},
}
