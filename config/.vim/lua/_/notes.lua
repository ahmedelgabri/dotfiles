local utils = require "_.utils"

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
      #args > 1 and table.concat(args, " ") or args[1]
    },
    " "
  ) or ""

  if has_a_path then
    path = path .. where
  end

  path =
    path ..
    vim.fn.strftime("%Y%m%d%H%M") .. (fname and " " .. fname or "") .. ".md"

  return {
    path,
    fname,
    vim.fn.strftime("%Y-%m-%dT%H:%M")
  }
end

function M.note_edit(...)
  local data = M.note_info(...)
  local path = data[1]
  local fname = data[2]
  local formatted_date = data[3]

  print(path)
  vim.cmd("edit " .. path)

  local frontmatter = [[
normal ggO---
title: %s
date: %s
tags:
---
]]

  vim.api.nvim_command(string.format(frontmatter, fname, formatted_date))
end

function M.wiki_edit(...)
  local args = {...}
  local fname = M.get_dir() .. "/wiki/" .. table.concat(args, " ") .. ".md"

  print(fname)

  vim.cmd("edit " .. fname)
end

function M.my_name(name)
  local data = M.note_info(name)
  local fname = vim.fn.fnamemodify(data[1], ":t")

  return fname
end

-- https://github.com/junegunn/fzf.vim#example-advanced-ripgrep-integration
function M.search_notes(query, fullscreen)
  local command_fmt =
    "rg --column --line-number --no-heading --color=always --smart-case"
  -- local initial_command =
  --   string.format(command_fmt, string.gsub(query, query, "'%1'"))
  -- local reload_command = string.format(command_fmt, "{q}")
  --
  -- local opts = {
  --   dir = M.get_dir(),
  --   options = {
  --     "--phony",
  --     "--query",
  --     query,
  --     "--bind",
  --     "change:reload:" .. reload_command
  --   }
  -- }
  --
  -- vim.fn["fzf#vim#grep"](
  --   initial_command,
  --   1,
  --   vim.fn["fzf#vim#with_preview"](opts),
  --   fullscreen
  -- )
  local opts = {
    search_dirs = {M.get_dir()}
  }

  require("telescope.builtin").live_grep(opts)
end

function M.open_in_obsidian()
  local str =
    string.format(
    "obsidian://open?path=%s",
    utils.urlencode(vim.fn.expand("%:p"))
  )

  print(str)
  vim.fn.system(
    string.format(
      vim.fn.executable("osascript") and [[osascript -e 'open location "%s"']] or
        [[xdg-open "%s"]],
      str
    )
  )
end

function M.note_in_obsidian(...)
  local data = M.note_info(...)
  local path = data[1]
  local fname = data[2]
  local formatted_date = data[3]

  local frontmatter = [[
---
title: %s
date: %s
tags:
---
]]

  local str =
    string.format(
    -- "obsidian://new?path=%s&content=%s", -- not working?
    -- utils.urlencode(path),
    "obsidian://new?vault=notes&file=%s/%s&content=%s",
    utils.urlencode(vim.fn.fnamemodify(path, ":h:t")),
    utils.urlencode(vim.fn.fnamemodify(path, ":t")),
    utils.urlencode(string.format(frontmatter, fname, formatted_date))
  )

  -- print(str)
  vim.fn.system(
    string.format(
      vim.fn.executable("osascript") and [[osascript -e 'open location "%s"']] or
        [[xdg-open "%s"]],
      str
    )
  )
end

return M
