local M = {}

function M.autocmd(...)
  local opts = ...
  -- store event(s)
  local event = opts.event
  -- remove it from opts
  opts.event = nil

  vim.api.nvim_create_autocmd(event, opts)
end

function M.augroup(name, autocmds, opts)
  local augroup = vim.api.nvim_create_augroup(
    name,
    vim.tbl_extend('force', { clear = true }, opts or {})
  )

  for _, au in ipairs(autocmds) do
    M.autocmd(vim.tbl_extend('force', au, { group = augroup }))
  end
end

return M
