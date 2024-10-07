local M = {}

local utils = require '_.utils'

function M.get_dir()
	return vim.env.NOTES_DIR
end

function M.note_info(fpath, ...)
	local args = { ... }
	local path = M.get_dir() .. '/'
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

function M.open_in_obsidian()
	local str = string.format(
		'obsidian://open?path=%s',
		utils.urlencode(vim.fn.expand '%:p')
	)

	print(str)
	vim.ui.open(str)
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

	local str = string.format(
		-- "obsidian://new?path=%s&content=%s", -- not working?
		-- utils.urlencode(path),
		'obsidian://new?vault=notes&file=%s/%s&content=%s',
		utils.urlencode(vim.fn.fnamemodify(path, ':h:t')),
		utils.urlencode(vim.fn.fnamemodify(path, ':t')),
		utils.urlencode(string.format(frontmatter, fname, formatted_date))
	)

	-- print(str)
	vim.ui.open(str)
end

function M.get_notes_completion()
	return vim.fn.map(
		vim.fn.getcompletion(M.get_dir() .. '/*', 'dir'),
		function(_, v)
			return string.gsub(v, M.get_dir() .. '/', '')
		end
	)
end

return M
