vim.keymap.set({ 'n' }, '<CR>', function()
	require('kulala').run()
end, { remap = true, desc = 'Run current HTTP request' })
