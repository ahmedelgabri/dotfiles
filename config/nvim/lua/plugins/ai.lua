local is_work_machine = function()
	return vim.fn.hostname() == 'rocket'
end

return {
	{
		'https://github.com/github/copilot.vim',
		enabled = is_work_machine(),
		-- build = ':Copilot auth',
		event = 'InsertEnter',
		config = function()
			-- https://github.com/orgs/community/discussions/82729#discussioncomment-8098207
			vim.g.copilot_ignore_node_version = true
			vim.g.copilot_no_tab_map = true
			vim.keymap.set(
				'i',
				'<Plug>(vimrc:copilot-dummy-map)',
				'copilot#Accept("")',
				{ silent = true, expr = true, desc = 'Copilot dummy accept' }
			)

			-- disable copilot outside of work folders and if node is not in $PATH
			if vim.fn.executable 'node' == 0 then
				vim.cmd 'Copilot disable'
			end
		end,
	},
	{
		'https://github.com/supermaven-inc/supermaven-nvim',
		enabled = not is_work_machine(),
		opts = {
			keymaps = {
				accept_suggestion = '<C-g>',
				ignore_filetypes = {
					starter = true,
					dotenv = true,
				},
				-- clear_suggestion = '<C-]>',
				-- accept_word = '<C-j>',
			},
			disable_inline_completion = false, -- disables inline completion for use with cmp
			disable_keymaps = false, -- disables built in keymaps for more manual control
		},
	},
}
