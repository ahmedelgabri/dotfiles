local M = {}

local function remap_opts(opts)
  return vim.tbl_extend('force', opts or {}, { remap = true })
end

local function is_debug(opts)
  local debug = opts.debug
  opts.debug = nil

  return debug
end

function M.remap(mode, lhs, rhs, opts)
  local debug = is_debug(opts or {})
  if debug then
    print('remap: ', mode, lhs, rhs, vim.inspect(opts))
  end
  vim.keymap.set(mode, lhs, rhs, remap_opts(opts))
end

function M.noremap(mode, lhs, rhs, opts)
  local debug = is_debug(opts or {})
  if debug then
    print('noremap: ', mode, lhs, rhs, vim.inspect(opts))
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.nmap(lhs, rhs, opts)
  M.remap('n', lhs, rhs, opts)
end

function M.nnoremap(lhs, rhs, opts)
  M.noremap('n', lhs, rhs, opts)
end

function M.vmap(lhs, rhs, opts)
  M.remap('v', lhs, rhs, opts)
end

function M.vnoremap(lhs, rhs, opts)
  M.noremap('v', lhs, rhs, opts)
end

function M.imap(lhs, rhs, opts)
  M.remap('i', lhs, rhs, opts)
end

function M.inoremap(lhs, rhs, opts)
  M.noremap('i', lhs, rhs, opts)
end

function M.smap(lhs, rhs, opts)
  M.remap('s', lhs, rhs, opts)
end

function M.snoremap(lhs, rhs, opts)
  M.noremap('s', lhs, rhs, opts)
end

function M.xmap(lhs, rhs, opts)
  M.remap('x', lhs, rhs, opts)
end

function M.xnoremap(lhs, rhs, opts)
  M.noremap('x', lhs, rhs, opts)
end

function M.tmap(lhs, rhs, opts)
  M.remap('t', lhs, rhs, opts)
end

function M.tnoremap(lhs, rhs, opts)
  M.noremap('t', lhs, rhs, opts)
end

function M.omap(lhs, rhs, opts)
  M.remap('o', lhs, rhs, opts)
end

function M.onoremap(lhs, rhs, opts)
  M.noremap('o', lhs, rhs, opts)
end

return M
