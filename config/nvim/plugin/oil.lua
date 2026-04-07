Pack.add {
	{ src = 'https://github.com/stevearc/oil.nvim', load = false },
}

-- Prevent netrw from loading so oil can take over directory buffers
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function ensure_oil()
	Pack.load 'oil.nvim'

	local detail = false

	require('oil').setup {
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
end

vim.keymap.set('n', '-', function()
	ensure_oil()
	require('oil').open()
end, { noremap = true, desc = 'Open parent directory' })

-- Bootstrap: load oil when opening a directory (e.g. `nvim .`)
local oil_bootstrap_group =
	vim.api.nvim_create_augroup('__oil_bootstrap__', { clear = true })

vim.api.nvim_create_autocmd('BufEnter', {
	group = oil_bootstrap_group,
	callback = function(ev)
		local path = vim.api.nvim_buf_get_name(ev.buf)
		if path ~= '' and vim.fn.isdirectory(path) == 1 then
			-- Remove this bootstrap autocmd, oil.setup registers its own
			vim.api.nvim_del_augroup_by_id(oil_bootstrap_group)
			ensure_oil()
			-- Schedule so we're outside the BufEnter callback before oil opens
			vim.schedule(function()
				require('oil').open(path)
			end)
		end
	end,
})
