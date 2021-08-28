local M = {}

local function map(mode, lhs, rhs, opts, noremap)
  local options = opts or {}
  local buffer = options.buffer
  options.buffer = nil

  -- options.unique = true
  if noremap == true then
    options.noremap = true
  end

  if buffer then
    vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, options)
  else
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end
end

function M.nmap(lhs, rhs, opts)
  map('n', lhs, rhs, opts)
end

function M.nnoremap(lhs, rhs, opts)
  map('n', lhs, rhs, opts, true)
end

function M.vmap(lhs, rhs, opts)
  map('v', lhs, rhs, opts)
end

function M.vnoremap(lhs, rhs, opts)
  map('v', lhs, rhs, opts, true)
end

function M.imap(lhs, rhs, opts)
  map('i', lhs, rhs, opts)
end

function M.inoremap(lhs, rhs, opts)
  map('i', lhs, rhs, opts, true)
end

function M.smap(lhs, rhs, opts)
  map('s', lhs, rhs, opts)
end

function M.snoremap(lhs, rhs, opts)
  map('s', lhs, rhs, opts, true)
end

function M.xmap(lhs, rhs, opts)
  map('x', lhs, rhs, opts)
end

function M.xnoremap(lhs, rhs, opts)
  map('x', lhs, rhs, opts, true)
end

function M.tmap(lhs, rhs, opts)
  map('t', lhs, rhs, opts)
end

function M.tnoremap(lhs, rhs, opts)
  map('t', lhs, rhs, opts, true)
end

function M.omap(lhs, rhs, opts)
  map('o', lhs, rhs, opts)
end

function M.onoremap(lhs, rhs, opts)
  map('o', lhs, rhs, opts, true)
end

return M
