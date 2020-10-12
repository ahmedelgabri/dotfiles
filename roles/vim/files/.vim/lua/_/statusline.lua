local utils = require'_.utils'

local M = {}

-- display lineNoIndicator (from drzel/vim-line-no-indicator)
local function line_no_indicator()
  local line_no_indicator_chars = {'⎺', '⎻', '─', '⎼', '⎽'}
  local current_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  local index = current_line

  if current_line == total_lines then
    index = #line_no_indicator_chars
  else
    local line_no_fraction = math.floor(current_line) / math.floor(total_lines)
    index = math.floor(line_no_fraction * #line_no_indicator_chars) + 1
  end

  return line_no_indicator_chars[index]
end

function M.git_info()
  if not vim.g.loaded_fugitive then
    return ''
  end

  local out = vim.fn.FugitiveHead(10)

  if out ~= '' then
    out = utils.get_icon('branch') .. ' ' .. out
  end

  return out
end

function M.update_filepath_highlights()
  if vim.bo.modified then
    vim.cmd('hi! link StatusLineFilePath DiffChange')
    vim.cmd('hi! link StatusLineNewFilePath DiffChange')
  else
    vim.cmd('hi! link StatusLineFilePath User6')
    vim.cmd('hi! link StatusLineNewFilePath User4')
  end

  return ''
end

function M.filepath()
  local base = vim.fn.expand('%:~:.:h')
  local filename = vim.fn.expand('%:~:.:t')
  local prefix = (vim.fn.empty(base) == 1 or base == '.') and '' or base..'/'
  local line = {}

  if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then
    table.insert(line, '%{luaeval("' .. "require('_.statusline').update_filepath_highlights()" .. '")}')
    table.insert(line, '%#StatusLineNewFilePath#')
    table.insert(line, '%f')
    table.insert(line, '%*')
  else
    table.insert(line, prefix)
    table.insert(line, '%*')
    table.insert(line, '%{luaeval("' .. "require('_.statusline').update_filepath_highlights()" .. '")}')
    table.insert(line, '%#StatusLineFilePath#')
    table.insert(line, filename)
  end

  return table.concat(line, '')
end

function M.readonly()
  local is_modifiable = vim.bo.modifiable == true
  local is_readonly = vim.bo.readonly == true

  if not is_modifiable and is_readonly then
    return utils.get_icon('lock') .. ' RO'
  end

  if is_modifiable and is_readonly then
    return 'RO'
  end

  if not is_modifiable and not is_readonly then
    return utils.get_icon('lock')
  end

  return ''
end

local mode_table = {
  no          = 'N-Operator Pending',
  v           = 'V.',
  V           = 'V·Line',
  ['\22']     = 'V·Block', -- \<C-V>
  s           = 'S.',
  S           = 'S·Line',
  ['\19']     = 'S·Block.', -- \<C-S>
  i           = 'I.',
  ic          = 'I·Compl',
  ix          = 'I·X-Compl',
  R           = 'R.',
  Rc          = 'Compl·Replace',
  Rx          = 'V·Replace',
  Rv          = 'X-Compl·Replace',
  c           = 'Command',
  cv          = 'Vim Ex',
  ce          = 'Ex',
  r           = 'Propmt',
  rm          = 'More',
  ['r?']      = 'Confirm',
  ['r?']      = 'Sh',
  t           = 'T.',
}

function M.mode()
  return mode_table[vim.fn.mode()] or (vim.fn.mode() == 'n' and '' or 'NOT IN MAP')
end

function M.rhs()
  return vim.fn.winwidth(0) > 80 and
  ('%s %02d/%02d:%02d'):format(line_no_indicator(), vim.fn.line('.'), vim.fn.line('$'), vim.fn.col('.')) or
  line_no_indicator()
end

function M.spell()
  if vim.wo.spell then
    return utils.get_icon('spell')
  end
  return ''
end

function M.paste()
  if vim.o.paste then
    return utils.get_icon('paste')
  end
  return ''
end

function M.file_info()
  local line = vim.bo.filetype
  if vim.bo.fileformat ~= 'unix' then
    return line .. vim.bo.fileformat
  end

  if vim.bo.fileencoding ~= 'utf-8' then
    return line .. vim.bo.fileencoding
  end

  return line
end

function M.word_count()
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'text' then
    return vim.fn.wordcount()["words"] ..' words'
  end
  return ''
end

function M.active()
  local line = {}

  if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
    table.insert(line, '%#StatusLineNC# ['.. vim.bo.filetype ..'] %f ')
    table.insert(line, '%5* %{luaeval("' .. "require('_.statusline').readonly()" .. '")} %w %*')
  else
    table.insert(line, '%6*%{luaeval("' .. "require'_.statusline'.git_info()" .. '")} %*')
    table.insert(line, '%<')
    table.insert(line, '%4*' .. M.filepath() .. '%*' )
    table.insert(line, '%4* %{luaeval("' .. "require('_.statusline').word_count()" .. '")} %*')
    table.insert(line, '%5* %{luaeval("' .. "require('_.statusline').readonly()" .. '")} %w %*')
    table.insert(line, '%9*%=%*')
    table.insert(line, ' %{luaeval("' .. "require('_.statusline').mode()" .. '")} %*')
    table.insert(line, '%#ErrorMsg# %{luaeval("' .. "require('_.statusline').paste()" .. '")} %*')
    table.insert(line, '%#WarningMsg# %{luaeval("' .. "require('_.statusline').spell()" .. '")} %*')
    table.insert(line, '%4* %{luaeval("' .. "require('_.statusline').file_info()" .. '")} %*')
    table.insert(line, '%4* %{luaeval("' .. "require('_.statusline').rhs()" .. '")} %*')
  end

  vim.api.nvim_win_set_option(0, 'statusline', table.concat(line, ''))
end

function M.inactive()
  local line = {}

  table.insert(line, '%#StatusLineNC#')
  table.insert(line, '%f')
  table.insert(line, '%*')

  vim.api.nvim_win_set_option(0, 'statusline', table.concat(line, ''))
end


function M.activate()
  vim.cmd(('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%d'):format(utils.get_color('Identifier', 'fg', 'gui'), utils.get_color('Identifier', 'fg', 'cterm')))

  utils.augroup('MyStatusLine', function ()
    vim.cmd("autocmd WinEnter,BufEnter * lua require'_.statusline'.active()")
    vim.cmd("autocmd WinLeave,BufLeave * lua require'_.statusline'.inactive()")
  end)
end

return M
