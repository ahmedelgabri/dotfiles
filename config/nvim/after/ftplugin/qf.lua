-- Wrap quickfix window
vim.cmd [[setlocal wrap]]
vim.cmd [[setlocal linebreak]]

-- Some settings.
vim.wo.nu = true
vim.wo.rnu = true

-- Add the cfilter plugin.
vim.cmd.packadd 'cfilter'
