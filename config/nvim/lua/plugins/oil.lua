return {
	{
		'https://github.com/stevearc/oil.nvim',
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
		config = function()
			local detail = false
			require('oil').setup {
				-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
				-- Set to false if you still want to use netrw.
				default_file_explorer = false,
				view_options = {
					show_hidden = true,
				},
				delete_to_trash = true,
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
			}
		end,
	},
}
