-- Make these commonly mistyped commands still work
vim.api.nvim_create_user_command('WQ', 'wq', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})
vim.api.nvim_create_user_command('Wqa', 'wqa', {})
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Q', 'q', {})

vim.api.nvim_create_user_command(
	'Light',
	'set background=light',
	{ desc = 'Set background to light' }
)
vim.api.nvim_create_user_command(
	'Dark',
	'set background=dark',
	{ desc = 'Set background to dark' }
)

-- Delete the current file and clear the buffer
vim.api.nvim_create_user_command(
	'Del',
	vim.fn.exists ':Delete' ~= 0 and ':Delete!' or [[:call delete(@%) | bdelete!]],
	{ desc = 'Delete the current file and clear the buffer' }
)

-- http://stackoverflow.com/a/39348498/2103996
vim.api.nvim_create_user_command('ClearRegisters', function()
	local regs = vim.split(
		'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"',
		''
	)
	for _, r in ipairs(regs) do
		vim.fn.setreg(r, {})
	end
end, { desc = 'Clear all registers' })
