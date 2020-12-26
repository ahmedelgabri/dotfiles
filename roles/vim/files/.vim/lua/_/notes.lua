local M = {}

function M.get_dir()
  return os.getenv("NOTES_DIR")
end

-- Investigate how to make this work with commands?
function M.get_notes_completion()
  return vim.fn.map(
    vim.fn.getcompletion(M.get_dir() .. "/*", "dir"),
    function(_, v)
      return string.gsub(v, M.get_dir() .. "/", "")
    end
  )
end

function M.note_info(fpath, ...)
  local args = {...}
  local path = M.get_dir() .. "/"
  local starts_with_a_path = vim.fn.fnamemodify(fpath, ":h")
  local starts_with_name = vim.fn.fnamemodify(fpath, ":t")
  local where = string.gsub(starts_with_a_path .. "/", "^\\.", "")
  local has_a_path = starts_with_a_path ~= "."
  local fname =
    table.concat(
    {
      has_a_path and starts_with_name or fpath,
      table.concat(args, " ")
    },
    " "
  ) or ""

  if has_a_path then
    path = path .. where
  end

  path = path .. vim.fn.strftime("%Y%m%d%H%M") .. " " .. fname .. ".md"

  return {
    path,
    fname,
    vim.fn.strftime("%A, %B %d, %Y, %H:%M")
  }
end

function M.note_edit(...)
  local data = M.note_info(...)
  local path = data[1]
  local fname = data[2]
  local formatted_date = data[3]

  print(path)
  vim.cmd("edit " .. path)

  local frontmatter = {
    "normal ggO---",
    "date: " .. formatted_date,
    "title: " .. fname,
    "tags:",
    "---"
  }

  vim.cmd(table.concat(frontmatter, "\n"))
end

function M.wiki_edit(...)
  local args = {...}
  local fname = M.get_dir() .. "/wiki/" .. table.concat(args, " ") .. ".md"

  print(fname)

  vim.cmd("edit " .. fname)
end

function M.my_name(name)
  local data = M.note_info(name)
  local fname = data[2]

  return fname
end

function M.search_notes()
  vim.fn["fzf#vim#files"](
    M.get_dir(),
    vim.fn["fzf#vim#with_preview"](
      {options = {"--preview-window=" .. vim.g.fzf_preview_window}}
    )
  )
end

return M
