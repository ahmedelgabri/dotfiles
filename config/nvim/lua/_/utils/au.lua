local M = {}

_.g = {}

_.g.autocommand_callbacks = {}

local callback_index = 0

function M.autocmd(name, pattern, cmd)
  local cmd_type = type(cmd)
  if cmd_type == 'function' then
    local key = '_' .. callback_index
    callback_index = callback_index + 1
    _.g.autocommand_callbacks[key] = cmd
    cmd = 'lua _.g.autocommand_callbacks.' .. key .. '()'
  elseif cmd_type ~= 'string' then
    error('autocmd(): unsupported cmd type: ' .. cmd_type)
  end
  vim.cmd('autocmd ' .. name .. ' ' .. pattern .. ' ' .. cmd)
end

function M.augroup(group, fn)
  vim.api.nvim_command('augroup ' .. group)
  vim.api.nvim_command 'autocmd!'
  fn()
  vim.api.nvim_command 'augroup END'
end

return M
