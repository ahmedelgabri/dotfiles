return function()
	vim.keymap.set({ 'n' }, '--', ':NvimTreeFindFile<CR>', { silent = true })

	require('nvim-tree').setup {
		view = {
			width = 20,
		},
		update_focused_file = {
			enable = true,
		},
		renderer = {
			indent_markers = {
				enable = false,
			},
			-- Normally README.md gets highlighted by default, which is a bit distracting.
			special_files = {},
			icons = {
				show = {
					git = true,
					file = false,
					folder = false,
					folder_arrow = false,
				},
			},
		},
		actions = {
			open_file = {
				quit_on_open = false,
				resize_window = true,
				window_picker = {
					enable = false,
				},
			},
		},
		-- vim-fugitive :GBrowse depends on netrw & this has to be set as early as possible
		-- maybe switch to https://github.com/ruifm/gitlinker.nvim?
		-- I only use fugitive for GBrowse 99% of the time & git branch in the statusline
		disable_netrw = false,
	}
end
