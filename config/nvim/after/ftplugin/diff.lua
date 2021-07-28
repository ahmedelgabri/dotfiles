if vim.api.nvim_win_get_option(0, 'diff') then
  vim.cmd [[syntax off]]
  vim.opt.number = true
else
  vim.cmd [[syntax on]]
  vim.opt.number = false
end
