-- Make these commonly mistyped commands still work
vim.api.nvim_create_user_command('WQ', 'wq', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})
vim.api.nvim_create_user_command('Wqa', 'wqa', {})
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Q', 'q', {})

vim.api.nvim_create_user_command('Light', 'set background=light', {})
vim.api.nvim_create_user_command('Dark', 'set background=dark', {})

-- Delete the current file and clear the buffer
vim.api.nvim_create_user_command(
  'Del',
  vim.fn.exists ':Delete' and ':Delete' or [[:call delete(@%) | bdelete!]],
  {}
)

vim.api.nvim_create_user_command(
  'ClearRegisters',
  [[call utils#ClearRegisters()]],
  {}
)
