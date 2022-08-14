return function()
	vim.g.undotree_WindowLayout = 2
	vim.g.undotree_SplitWidth = 50
	vim.g.undotree_SetFocusWhenToggle = 1

	vim.keymap.set({ 'n' }, '<leader>u', ':UndotreeToggle<CR>', { silent = true })
end
