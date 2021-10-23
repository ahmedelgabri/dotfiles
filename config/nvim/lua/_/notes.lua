_.notes = {}

local utils = require '_.utils'

function _.notes.get_dir()
  return vim.env.NOTES_DIR
end

function _.notes.note_info(fpath, ...)
  local args = { ... }
  local path = _.notes.get_dir() .. '/'
  local starts_with_a_path = vim.fn.fnamemodify(fpath, ':h')
  local starts_with_name = vim.fn.fnamemodify(fpath, ':t')
  local where = string.gsub(starts_with_a_path .. '/', '^\\.', '')
  local has_a_path = starts_with_a_path ~= '.'
  local fname = table.concat({
    has_a_path and starts_with_name or fpath,
    #args > 1 and table.concat(args, ' ') or args[1],
  }, ' ') or ''

  if has_a_path then
    path = path .. where
  end

  path = path
    .. vim.fn.strftime '%Y%m%d%H%M'
    .. (fname and ' ' .. fname or '')
    .. '.md'

  return {
    path,
    fname,
    vim.fn.strftime '%Y-%m-%dT%H:%M',
  }
end

-- https://github.com/junegunn/fzf.vim#example-advanced-ripgrep-integration
function _.notes.search_notes(query, fullscreen)
  local command_fmt =
    'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  local initial_command = string.format(
    command_fmt,
    string.gsub(query, query, "'%1'")
  )
  local reload_command = string.format(command_fmt, '{q}')

  local opts = {
    dir = _.notes.get_dir(),
    options = {
      '--phony',
      '--query',
      query,
      '--bind',
      'change:reload:' .. reload_command,
    },
  }

  vim.fn['fzf#vim#grep'](
    initial_command,
    1,
    vim.fn['fzf#vim#with_preview'](opts),
    fullscreen
  )
end

function _.notes.open_in_obsidian()
  local str = string.format(
    'obsidian://open?path=%s',
    utils.urlencode(vim.fn.expand '%:p')
  )

  print(str)
  vim.fn.system(
    string.format(
      vim.fn.executable 'osascript'
          and [[osascript -e 'open location "%s"']]
        or [[xdg-open "%s"]],
      str
    )
  )
end

function _.notes.note_in_obsidian(...)
  local data = _.notes.note_info(...)
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

  local str = string.format(
    -- "obsidian://new?path=%s&content=%s", -- not working?
    -- utils.urlencode(path),
    'obsidian://new?vault=notes&file=%s/%s&content=%s',
    utils.urlencode(vim.fn.fnamemodify(path, ':h:t')),
    utils.urlencode(vim.fn.fnamemodify(path, ':t')),
    utils.urlencode(string.format(frontmatter, fname, formatted_date))
  )

  -- print(str)
  vim.fn.system(
    string.format(
      vim.fn.executable 'osascript'
          and [[osascript -e 'open location "%s"']]
        or [[xdg-open "%s"]],
      str
    )
  )
end
