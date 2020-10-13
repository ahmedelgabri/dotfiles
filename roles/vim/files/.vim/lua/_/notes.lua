local M = {}

local sep = '_'

function M.get_dir()
  return os.getenv('NOTES_DIR')
end

-- Investigate how to make this work with commands?
function M.get_notes_completion()
  return vim.fn.map(vim.fn.getcompletion(M.get_dir() .. '/*/**/', 'dir'), function(_, v) return string.gsub(v, M.get_dir() .. '/', '') end)
end

function M.note_info(f_args)
  local path = M.get_dir() .. '/'
  local fname = ''

  if #f_args >= 1 then
    local where = string.gsub(vim.fn.fnamemodify(f_args[1], ':h') .. '/', '^.', '')

    path = path .. where
    fname = vim.fn.fnamemodify(f_args[1], ':t:r'):lower() or ''
  end

  local has_fname = fname ~= ''

  path = path .. vim.fn.strftime('%Y-%m-%dT%H-%M-%S') .. (has_fname and sep or '') .. fname .. '.md'
  local tail = vim.fn.fnamemodify(path, ':t:r')

  return {path, has_fname and vim.fn.split(tail, sep)[2] or '', vim.fn.strftime('%A, %B %d, %Y, %H:%M')}
end

function M.note_edit(f_args)
  local data = M.note_info(f_args)
  local path = data[1]
  local fname = data[2]
  local formatted_date = data[3]

  print(path)
  vim.cmd('edit ' .. path)

  local frontmatter = { 'normal ggO---', 'date: ' .. formatted_date, 'title: ' .. fname, '---' }
  vim.cmd(table.concat(frontmatter, '\n'))

  vim.cmd('silent! packadd goyo.vim | Goyo')
end

function M.wiki_edit(f_args)
  local wiki_sep = ''

  if #f_args > 0 then
    wiki_sep = sep
  end

  local fname = M.get_dir() .. '/wiki/' .. table.concat(f_args, wiki_sep) .. '.md'

  print(fname)

  vim.cmd('edit ' .. fname)

  vim.cmd('silent! packadd goyo.vim | Goyo')
end

function M.my_name(name)
  local data = M.note_info(name)
  local fname = data[2]

  return fname
end

function M.search_notes()
  vim.fn['fzf#vim#files'](M.get_dir(), vim.fn['fzf#vim#with_preview']({ options = { '--preview-window=' .. vim.g.fzf_preview_window } }))
end

return M
