local au = require '_.utils.au'
local map = require '_.utils.map'

local M = {}

function M.get_icon(icon_name)
  local ICONS = {
    paste = '⍴',
    spell = '✎',
    branch = vim.env.PURE_GIT_BRANCH ~= '' and vim.fn.trim(
      vim.env.PURE_GIT_BRANCH
    ) or ' ',
    error = '×',
    information = '●',
    warning = '!',
    hint = '›',
    lock = '',
    success = ' ',
    -- success = ' '
  }

  return ICONS[icon_name] or ''
end

function M.get_color(synID, what, mode)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(synID)), what, mode)
end

function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.urlencode(str)
  str = string.gsub(
    str,
    "([^0-9a-zA-Z !'()*._~-])", -- locale independent
    function(c)
      return string.format('%%%02X', string.byte(c))
    end
  )

  str = string.gsub(str, ' ', '%%20')
  return str
end

function M.plugin_installed(name)
  local has_packer = pcall(require, 'packer')

  if not has_packer then
    return
  end

  return has_packer and packer_plugins ~= nil and packer_plugins[name]
end

function M.plugin_loaded(name)
  return M.plugin_installed(name) and packer_plugins[name].loaded
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = ':: Local ::' })
end

function M.plaintext()
  vim.cmd [[setlocal spell]]
  vim.cmd [[setlocal linebreak]]
  vim.cmd [[setlocal nolist]]
  vim.cmd [[setlocal wrap]]

  if vim.bo.filetype == 'gitcommit' then
    -- Git commit messages body are constraied to 72 characters
    vim.cmd [[setlocal textwidth=72]]
  else
    vim.cmd [[setlocal textwidth=0]]
    vim.cmd [[setlocal wrapmargin=0]]
  end

  -- Break undo sequences into chunks (after punctuation); see: `:h i_CTRL-G_u`
  -- https://twitter.com/vimgifs/status/913390282242232320
  map.inoremap('.', '.<c-g>u', { buffer = true })
  map.inoremap('?', '?<c-g>u', { buffer = true })
  map.inoremap('!', '!<c-g>u', { buffer = true })
  map.inoremap(',', ',<c-g>u', { buffer = true })
end

return M
