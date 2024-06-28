return {
	'https://github.com/mbbill/undotree',
	cmd = 'UndotreeToggle',
	keys = {
		{
			'<leader>u',
			vim.cmd.UndotreeToggle,
			noremap = true,
			desc = 'Toggle [U]ndotree',
		},
	},
	init = function()
		vim.g.undotree_WindowLayout = 2
		vim.g.undotree_SplitWidth = 50
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
