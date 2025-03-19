return {
	{
		'https://github.com/stevearc/oil.nvim',
		-- avoid lazy loading oil in order to use it as a file explorer instead of netrw
		lazy = false,
		keys = {
			{
				'-',
				function()
					require('oil').open()
				end,
				noremap = true,
				desc = 'Open parent directory',
			},
		},
		opts = function(_, opts)
			local detail = false

			return vim.tbl_deep_extend('force', opts or {}, {
				-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
				-- Set to false if you still want to use netrw.
				default_file_explorer = true,
				view_options = {
					show_hidden = true,
				},
				delete_to_trash = true,
				win_options = {
					cursorline = true,
				},
				keymaps = {
					['gd'] = {
						desc = 'Toggle file detail view',
						callback = function()
							detail = not detail
							if detail then
								require('oil').set_columns {
									'icon',
									'permissions',
									'size',
									'mtime',
								}
							else
								require('oil').set_columns { 'icon' }
							end
						end,
					},
				},
			})
		end,
	},
}
