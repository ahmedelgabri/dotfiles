local M = {}

local NOTES_DIR = vim.fn.expand('$NOTES_DIR')
local sep = '_'

-- Investigate how to make this work with commands?
-- M.get_notes_completion = function(ArgLead, CmdLine, CursorPos)
--   return vim.fn.map(vim.fn.getcompletion(M.get_dir() .. '/*/**/', 'dir'), function(_, v) return vim.fn.substitute(v, 'mC^'.. os.getenv('HOME') ..'/', '~/', '') end)
-- end

M.get_dir = function()
  return NOTES_DIR
end

M.note_info = function(f_args)
  local path = M.get_dir() .. '/'
  local fname = #f_args > 0 and f_args[1]:lower():gsub("%s+", "") or ''

  if #f_args > 0 and string.match(f_args[1], "^~/") == '~/' then
    path = vim.fn.fnamemodify(f_args[1], ':h') .. '/'
    fname = vim.fn.fnamemodify(f_args[1], ':t:r'):lower()
  end

  local has_fname = fname ~= ''

  path = path .. vim.fn.strftime('%Y-%m-%dT%H-%M-%S') .. (has_fname and sep or '') .. fname .. '.md'
  local tail = vim.fn.fnamemodify(path, ':t:r')

  return {path, has_fname and vim.fn.split(tail, sep)[2] or ''}
end

M.note_edit = function(f_args)
  local data = M.note_info(f_args)
  local path = data[1]
  local fname = data[2]

  print(path)
  vim.cmd('edit ' .. path)

  local frontmatter = { "normal ggO---", "date: " .. vim.fn.strftime('%A, %B %d, %Y, %H:%M'), "title: " .. fname, "---" }
  vim.cmd(table.concat(frontmatter, '\n'))

  vim.cmd('silent! packadd goyo.vim | Goyo')
end

M.wiki_edit = function(f_args)
  local wiki_sep = ''

  if #f_args > 0 then
    wiki_sep = sep
  end

  local fname = M.get_dir() .. '/wiki/' .. table.concat(f_args, wiki_sep) .. '.md'

  print(fname)

  vim.cmd('edit ' .. fname)

  vim.cmd('silent! packadd goyo.vim | Goyo')
end

M.my_name = function(name)
  local data = M.note_info(name)
  local fname = data[2]

  return fname
end

M.search_notes = function()
  vim.fn['fzf#vim#files'](M.get_dir(), vim.fn['fzf#vim#with_preview']({ options = { '--preview-window=' .. vim.g.fzf_preview_window } }))
end

return M
