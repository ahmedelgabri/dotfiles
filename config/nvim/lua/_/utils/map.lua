local M = {}

local function map(mode, lhs, rhs, opts)
  local buffer = opts.buffer
  opts.buffer = nil

  if buffer then
    vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
  else
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

function M.nmap(lhs, rhs, opts)
  map('n', lhs, rhs, opts or {})
end

function M.nnoremap(lhs, rhs, opts)
  map('n', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.vmap(lhs, rhs, opts)
  map('v', lhs, rhs, opts or {})
end

function M.vnoremap(lhs, rhs, opts)
  map('v', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.imap(lhs, rhs, opts)
  map('i', lhs, rhs, opts or {})
end

function M.inoremap(lhs, rhs, opts)
  map('i', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.smap(lhs, rhs, opts)
  map('s', lhs, rhs, opts or {})
end

function M.snoremap(lhs, rhs, opts)
  map('s', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.xmap(lhs, rhs, opts)
  map('x', lhs, rhs, opts or {})
end

function M.xnoremap(lhs, rhs, opts)
  map('x', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.tmap(lhs, rhs, opts)
  map('t', lhs, rhs, opts or {})
end

function M.tnoremap(lhs, rhs, opts)
  map('t', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

function M.omap(lhs, rhs, opts)
  map('o', lhs, rhs, opts or {})
end

function M.onoremap(lhs, rhs, opts)
  map('o', lhs, rhs, vim.tbl_extend('force', opts or {}, { noremap = true }))
end

return M
