local M = {}

M.bmap = function(mode, key, result, opts)
  vim.fn.nvim_buf_set_keymap(0, mode, key, result, opts)
end

M.gmap = function(mode, key, result, opts)
  vim.fn.nvim_set_keymap(mode, key, result, opts)
end

return M
