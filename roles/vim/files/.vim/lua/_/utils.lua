local M = {}

function M.bmap(mode, key, result, opts)
  vim.api.nvim_buf_set_keymap(0, mode, key, result, opts)
end

function M.gmap(mode, key, result, opts)
  vim.api.nvim_set_keymap(mode, key, result, opts)
end

function M.Augroup(group, fn)
  vim.api.nvim_command("augroup "..group)
  vim.api.nvim_command("autocmd!")
  fn()
  vim.api.nvim_command("augroup END")
end

return M
