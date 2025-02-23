return {
	'https://github.com/mikavilpas/yazi.nvim',
	event = 'VeryLazy',
	keys = {
		{
			'<leader>-',
			mode = { 'n', 'v' },
			'<cmd>Yazi<cr>',
			desc = 'Open yazi at the current file',
		},
		{
			'-',
			'<cmd>Yazi cwd<cr>',
			desc = "Open the file manager in nvim's working directory",
		},
		{
			'<c-up>',
			'<cmd>Yazi toggle<cr>',
			desc = 'Resume the last yazi session',
		},
	},
	init = function()
		vim.g.custom_explorer = true
	end,
	opts = {
		open_multiple_tabs = true,
		open_for_directories = true,
		keymaps = {
			show_help = '?',
		},
		-- log_level = vim.log.levels.DEBUG,
		integrations = {
			grep_in_directory = 'snacks.picker',
			grep_in_selected_files = 'snacks.picker',
			resolve_relative_path_application = 'realpath',
		},
		future_features = {
			process_events_live = true,
		},
	},
}
