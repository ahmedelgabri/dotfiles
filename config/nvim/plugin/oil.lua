Pack.add {
	'https://github.com/stevearc/oil.nvim',
}

if not Pack.load 'oil.nvim' then
	return
end

vim.keymap.set('n', '-', function()
	require('oil').open()
end, { noremap = true, desc = 'Open parent directory' })

local detail = false

require('oil').setup {
	-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
	-- Set to false if you still want to use netrw.
	default_file_explorer = true,
	watch_for_changes = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
	view_options = { show_hidden = true },
	keymaps = {
		['q'] = { 'actions.close', mode = 'n' },
		['?'] = 'actions.preview',
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
