local utils = require "_.utils"

local M = {}

---------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------

-- display lineNoIndicator (from drzel/vim-line-no-indicator)
local function line_no_indicator()
  local line_no_indicator_chars = {"⎺", "⎻", "─", "⎼", "⎽"}
  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local index = current_line

  if current_line == 1 then
    index = 1
  elseif current_line == total_lines then
    index = #line_no_indicator_chars
  else
    local line_no_fraction = math.floor(current_line) / math.floor(total_lines)
    index = math.ceil(line_no_fraction * #line_no_indicator_chars)
  end

  return line_no_indicator_chars[index]
end

---------------------------------------------------------------------------------
-- Main functions
---------------------------------------------------------------------------------

function M.git_info()
  if not vim.g.loaded_fugitive then
    return ""
  end

  local out = vim.fn.FugitiveHead(10)

  if out ~= "" then
    out = utils.get_icon("branch") .. "  " .. out
  end

  return out
end

function M.update_filepath_highlights()
  if vim.bo.modified then
    vim.cmd("hi! link StatusLineFilePath DiffChange")
    vim.cmd("hi! link StatusLineNewFilePath DiffChange")
  else
    vim.cmd("hi! link StatusLineFilePath User6")
    vim.cmd("hi! link StatusLineNewFilePath User4")
  end

  return ""
end

function M.get_filepath_parts()
  local base = vim.fn.expand("%:~:.:h")
  local filename = vim.fn.expand("%:~:.:t")
  local prefix = (vim.fn.empty(base) == 1 or base == ".") and "" or base .. "/"

  return {base, filename, prefix}
end

function M.filepath()
  local parts = M.get_filepath_parts()
  local prefix = parts[3]
  local filename = parts[2]

  local line = [[%{luaeval("require'_.statusline'.get_filepath_parts()[3]")}]]
  line = line .. "%*"
  line =
    line .. [[%{luaeval("require'_.statusline'.update_filepath_highlights()")}]]
  line = line .. "%#StatusLineFilePath#"
  line = line .. [[%{luaeval("require'_.statusline'.get_filepath_parts()[2]")}]]

  if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then
    line = [[%{luaeval("require'_.statusline'.update_filepath_highlights()")}]]
    line = line .. "%#StatusLineNewFilePath#"
    line = line .. "%f"
    line = line .. "%*"
  end

  return line
end

function M.readonly()
  local is_modifiable = vim.bo.modifiable == true
  local is_readonly = vim.bo.readonly == true

  if not is_modifiable and is_readonly then
    return utils.get_icon("lock") .. " RO"
  end

  if is_modifiable and is_readonly then
    return "RO"
  end

  if not is_modifiable and not is_readonly then
    return utils.get_icon("lock")
  end

  return ""
end

local mode_table = {
  no = "N-Operator Pending",
  v = "V.",
  V = "V·Line",
  [""] = "V·Block", -- this is not ^V, but it's , they're different
  s = "S.",
  S = "S·Line",
  [""] = "S·Block",
  i = "I.",
  ic = "I·Compl",
  ix = "I·X-Compl",
  R = "R.",
  Rc = "Compl·Replace",
  Rx = "V·Replace",
  Rv = "X-Compl·Replace",
  c = "Command",
  cv = "Vim Ex",
  ce = "Ex",
  r = "Propmt",
  rm = "More",
  ["r?"] = "Confirm",
  ["!"] = "Sh",
  t = "T."
}

function M.mode()
  return mode_table[vim.fn.mode()] or
    (vim.fn.mode() == "n" and "" or "NOT IN MAP")
end

function M.rhs()
  return vim.fn.winwidth(0) > 80 and
    ("%s %02d/%02d:%02d"):format(
      line_no_indicator(),
      vim.fn.line("."),
      vim.fn.line("$"),
      vim.fn.col(".")
    ) or
    line_no_indicator()
end

function M.spell()
  if vim.wo.spell then
    return utils.get_icon("spell")
  end
  return ""
end

function M.paste()
  if vim.o.paste then
    return utils.get_icon("paste")
  end
  return ""
end

function M.file_info()
  local line = vim.bo.filetype
  if vim.bo.fileformat ~= "unix" then
    return line .. " " .. vim.bo.fileformat
  end

  if vim.bo.fileencoding ~= "utf-8" then
    return line .. " " .. vim.bo.fileencoding
  end

  return line
end

function M.word_count()
  if vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
    return vim.fn.wordcount()["words"] .. " words"
  end
  return ""
end

function M.filetype()
  return vim.bo.filetype
end

---------------------------------------------------------------------------------
-- Statusline
---------------------------------------------------------------------------------

function M.active()
  local line = [[%6*%{luaeval("require'_.statusline'.git_info()")} %*]]

  line = line .. "%<"
  line = line .. "%4*" .. M.filepath() .. "%*"
  line = line .. [[%4* %{luaeval("require'_.statusline'.word_count()")} %*]]
  line = line .. [[%5* %{luaeval("require'_.statusline'.readonly()")} %w %*]]
  line = line .. "%9*%=%*"
  line = line .. [[ %{luaeval("require'_.statusline'.mode()")} %*]]
  line = line .. [[%#ErrorMsg# %{luaeval("require'_.statusline'.paste()")} %*]]
  line =
    line .. [[%#WarningMsg# %{luaeval("require'_.statusline'.spell()")} %*]]
  line = line .. [[%4* %{luaeval("require'_.statusline'.file_info()")} %*]]
  line = line .. [[%4* %{luaeval("require'_.statusline'.rhs()")} %*]]

  if vim.bo.filetype == "help" or vim.bo.filetype == "man" then
    line = [[%#StatusLineNC# %{luaeval("require'_.statusline'.filetype()")} %f]]
    line = line .. [[%5* %{luaeval("require'_.statusline'.readonly()")} %w %*]]
  end

  vim.api.nvim_win_set_option(0, "statusline", line)
end

function M.inactive()
  local line = "%#StatusLineNC#%f%*"

  vim.api.nvim_win_set_option(0, "statusline", line)
end

function M.activate()
  vim.cmd(
    ("hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%d"):format(
      utils.get_color("Identifier", "fg", "gui"),
      utils.get_color("Identifier", "fg", "cterm")
    )
  )

  utils.augroup(
    "MyStatusLine",
    function()
      vim.cmd("autocmd WinEnter,BufEnter * lua require'_.statusline'.active()")
      vim.cmd(
        "autocmd WinLeave,BufLeave * lua require'_.statusline'.inactive()"
      )
    end
  )
end

return M
