---@class _.notes.CreateOptions
---@field notebook_path? string
---@field dir? string
---@field template? string
---@field title? string
---@field prompt? boolean
---@field edit? boolean
---@field [string] any

---@class _.notes
local M = {}
local frontmatter = require '_.notes.frontmatter'

---@type table<string, _.notes.CreateOptions>
local aliases = {
	interview = { dir = 'work', template = 'interview.md' },
	j = { dir = 'journal', prompt = false },
	journal = { dir = 'journal', prompt = false },
	lc = { dir = 'work', template = 'live-coding.md' },
	p = { dir = 'personal' },
	personal = { dir = 'personal' },
	rfc = { dir = 'work', template = 'rfc.md' },
	sd = { dir = 'work', template = 'system-design.md' },
	til = { dir = 'til' },
	w = { dir = 'work' },
	work = { dir = 'work' },
	y = { dir = 'personal', template = 'year.md' },
	year = { dir = 'personal', template = 'year.md' },
	d = { dir = 'personal', template = 'decade.md' },
	decade = { dir = 'personal', template = 'decade.md' },
}

---@type table<string, string>
local command_aliases = {
	NoteJournal = 'journal',
	NotePersonal = 'personal',
	NoteRfc = 'rfc',
	NoteTil = 'til',
	NoteWork = 'work',
}

---@type table<string, boolean>
local ignored_dirs = {
	['.git'] = true,
	['.obsidian'] = true,
	['.zk'] = true,
	assets = true,
}

---@type string[]
local alias_names = vim.tbl_keys(aliases)
table.sort(alias_names)

---@param message string
---@param level? integer
---@return nil
local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = 'notes' })
end

---@param args? string
---@return string?
---@return string
local function first_word(args)
	local word, rest = vim.trim(args or ''):match '^(%S+)%s*(.*)$'
	return word, vim.trim(rest or '')
end

---@return string[]
local function note_subdirs()
	local root = frontmatter.notes_dir()
	if root == nil then
		return {}
	end

	local dirs = {}
	for name, type in vim.fs.dir(root) do
		if
			type == 'directory'
			and not ignored_dirs[name]
			and name:sub(1, 1) ~= '.'
		then
			table.insert(dirs, name)
		end
	end

	table.sort(dirs)
	return dirs
end

---@param path? string
---@return boolean
local function is_note_subdir(path)
	local root = frontmatter.notes_dir()
	if root == nil or path == nil or path == '' then
		return false
	end
	if path:sub(1, 1) == '.' or path:find '/%.' then
		return false
	end

	local stat = vim.uv.fs_stat(vim.fs.joinpath(root, path))
	return stat ~= nil and stat.type == 'directory'
end

---@param args string
---@return _.notes.CreateOptions
local function eval_options(args)
	local chunk, err = loadstring('return ' .. args)
	if chunk == nil then
		error(err)
	end

	local ok, value = pcall(chunk)
	if not ok then
		error(value)
	end
	if type(value) ~= 'table' then
		error ':N Lua form must evaluate to a table'
	end

	return value
end

---@param args? string
---@return _.notes.CreateOptions
local function resolve_options(args)
	local trimmed = vim.trim(args or '')
	if trimmed:sub(1, 1) == '{' then
		return eval_options(trimmed)
	end

	local key, title = first_word(trimmed)
	local defaults = {}

	if key ~= nil and aliases[key] ~= nil then
		defaults = aliases[key]
	elseif is_note_subdir(key) then
		defaults = { dir = key }
	else
		title = trimmed
	end

	local options = vim.deepcopy(defaults)
	if options.prompt ~= false and title == '' then
		title = vim.fn.input 'Title: '
	end
	if title ~= '' then
		options.title = title
	end

	return options
end

---@param arg_lead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
local function complete_targets(arg_lead, cmdline, cursorpos)
	local before_cursor = cmdline:sub(1, cursorpos - 1)
	local args = before_cursor:match '^%S+%s*(.*)$' or ''
	if args:find '%s' then
		return {}
	end

	local seen = {}
	local targets = {}
	for _, source in ipairs { alias_names, note_subdirs() } do
		for _, target in ipairs(source) do
			if not seen[target] and vim.startswith(target, arg_lead) then
				seen[target] = true
				table.insert(targets, target)
			end
		end
	end

	return targets
end

---@param options? _.notes.CreateOptions
---@return nil
local function new_note(options)
	options = options or {}

	local notebook_path = options.notebook_path or frontmatter.notes_dir()
	if notebook_path == nil then
		notify(
			'NOTES_DIR/ZK_NOTEBOOK_DIR is not set or does not exist',
			vim.log.levels.ERROR
		)
		return
	end

	local edit = options.edit ~= false
	local api_options = vim.deepcopy(options)
	api_options.notebook_path = nil
	api_options.prompt = nil
	api_options.edit = nil

	require('zk.api').new(notebook_path, api_options, function(err, result)
		vim.schedule(function()
			if err ~= nil then
				notify(tostring(err), vim.log.levels.ERROR)
				return
			end
			if result == nil or result.path == nil then
				return
			end

			if edit then
				vim.cmd.edit(vim.fn.fnameescape(result.path))
				frontmatter.normalize(0, { write = true })
			else
				frontmatter.normalize_path(result.path, { write = true })
			end
		end)
	end)
end

---@param args? string
---@param opts? _.notes.CreateOptions
---@return nil
function M.new_from_args(args, opts)
	local ok, options = pcall(resolve_options, args)
	if not ok then
		notify(tostring(options), vim.log.levels.ERROR)
		return
	end

	if opts ~= nil and opts.edit == false then
		options.edit = false
	end

	new_note(options)
end

---@return nil
function M.setup()
	vim.api.nvim_create_user_command('Note', function(ev)
		M.new_from_args(ev.args, { edit = not ev.bang })
	end, {
		bang = true,
		complete = complete_targets,
		desc = 'Create a zk note',
		force = true,
		nargs = '*',
	})

	vim.api.nvim_create_user_command('NoteFrontmatter', function(ev)
		frontmatter.normalize(0, { write = ev.bang })
	end, {
		bang = true,
		desc = 'Normalize note frontmatter',
		force = true,
	})

	-- :N is a built-in Ex command, so use an abbreviation for the shortcut.
	vim.cmd [[cnoreabbrev <expr> N getcmdtype() ==# ':' && getcmdline() ==# 'N' ? 'Note' : 'N']]

	for name, alias in pairs(command_aliases) do
		vim.api.nvim_create_user_command(name, function(ev)
			M.new_from_args(alias .. ' ' .. ev.args, { edit = not ev.bang })
		end, {
			bang = true,
			desc = 'Create a zk note',
			force = true,
			nargs = '*',
		})
	end

	vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
		pattern = { '*.md', '*.markdown' },
		callback = function(ev)
			if frontmatter.is_note(ev.buf) and frontmatter.is_empty(ev.buf) then
				frontmatter.normalize(ev.buf, { write = true })
			end
		end,
	})
end

return M
