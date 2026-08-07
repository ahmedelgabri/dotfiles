-- Hand-rolled mini.starter dashboard: header art, random quote,
-- bookmarks, MRU lists (cwd and global), and per-project session
-- entries. plugin/mini.lua wires M.content_hook into mini.starter.
local uv = vim.uv or vim.loop
local width = 60

local header = {
	-- https://github.com/NvChad/NvChad/discussions/2755#discussioncomment-8960250
	'           ▄ ▄                   ',
	'       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ',
	'       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ',
	'    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ',
	'  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ',
	'  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄',
	'▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █',
	'█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █',
	'    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ',
}

local quote = require('_.quotes').random_quote()

local function unit(str, hl)
	return { string = str, type = 'empty', hl = hl }
end

local function line_width(line)
	local ret = 0
	for _, item in ipairs(line) do
		ret = ret + vim.api.nvim_strwidth(item.string)
	end
	return ret
end

local function pad_right(line, target)
	local missing = target - line_width(line)
	if missing > 0 then
		table.insert(line, unit((' '):rep(missing)))
	end
	return line
end

local function add_line(lines, line)
	table.insert(lines, pad_right(line, width))
end

local function add_blank(lines, count)
	for _ = 1, count do
		table.insert(lines, { unit '' })
	end
end

local function wrap_text(line)
	local wrapped_lines = {}
	local line_start = 1

	while line_start <= #line do
		local line_end = math.min(line_start + width - 1, #line)

		if line_end < #line then
			local space_pos = line:sub(line_start, line_end):find ' [^ ]*$'
			if space_pos then
				line_end = line_start + space_pos - 1
			end
		end

		local segment = line:sub(line_start, line_end):gsub('^%s*', '')
		if segment ~= '' then
			table.insert(wrapped_lines, segment)
		end

		line_start = line_end + 1
	end

	return wrapped_lines
end

local function filter_common(file)
	return file:match 'COMMIT_EDITMSG' == nil
		and file:match '/tmp' == nil
		-- vim help files
		and file:match '/share/nvim/runtime/doc' == nil
end

local function oldfiles(filter_map)
	filter_map = vim.tbl_extend('force', {
		[vim.fn.stdpath 'data'] = false,
		[vim.fn.stdpath 'cache'] = false,
		[vim.fn.stdpath 'state'] = false,
	}, filter_map or {})

	local filters = {}
	for path, want in pairs(filter_map) do
		table.insert(filters, { path = vim.fs.normalize(path), want = want })
	end

	local ret = {}
	local seen = {}
	for _, oldfile in ipairs(vim.v.oldfiles) do
		local file = vim.fs.normalize(oldfile)
		local want = not seen[file]
		seen[file] = true

		for _, filter in ipairs(filters) do
			local matches = file:sub(1, #filter.path) == filter.path
				and (
					file == filter.path
					or file:sub(#filter.path + 1, #filter.path + 1):find '[/\\]' ~= nil
				)
			if matches ~= filter.want then
				want = false
				break
			end
		end

		if want and uv.fs_stat(file) then
			table.insert(ret, file)
		end
	end

	return ret
end

local function icon(name, category)
	local ok, mini_icons = pcall(require, 'mini.icons')
	if ok then
		local icon_text, icon_hl = mini_icons.get(category or 'file', name)
		return icon_text or '󰈔 ', icon_hl or 'Special'
	end

	return category == 'directory' and '󰉋 ' or '󰈔 ', 'Special'
end

local function edit_file(file)
	return function()
		vim.cmd('edit ' .. vim.fn.fnameescape(file))
	end
end

local function pack_update(opts)
	return function()
		if opts then
			vim.pack.update(nil, opts)
		else
			vim.pack.update()
		end
	end
end

local function pick_files()
	local fzf_ok, fzf = pcall(require, 'fzf-lua')
	if fzf_ok then
		fzf.files()
	end
end

local function read_session_or_pick()
	if _G.MiniSessions == nil then
		pick_files()
		return
	end

	local session_loaded = false
	vim.api.nvim_create_autocmd('SessionLoadPost', {
		once = true,
		callback = function()
			session_loaded = true
		end,
	})

	vim.defer_fn(function()
		if not session_loaded then
			pick_files()
		end
	end, 100)

	_G.MiniSessions.read()
end

local function get_git_root(path)
	path = vim.fs.normalize(path == '' and uv.cwd() or path)

	if uv.fs_stat(path .. '/.git') ~= nil then
		return path
	end

	for dir in vim.fs.parents(path) do
		if uv.fs_stat(dir .. '/.git') ~= nil then
			return vim.fs.normalize(dir)
		end
	end

	return vim.env.GIT_WORK_TREE
end

local function next_autokey(used)
	local keys = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
	keys = keys:gsub('[hjklq]', '')

	for key in pairs(used) do
		keys = keys:gsub(vim.pesc(key), '', 1)
	end

	return function()
		local key = keys:sub(1, 1)
		keys = keys:sub(2)
		return key
	end
end

local function bookmark_items()
	local items = {
		{
			key = 'e',
			icon = ' ',
			desc = 'New File',
			action = function()
				vim.cmd.enew()
			end,
		},
		{
			key = 'u',
			icon = '󰚰 ',
			desc = 'vim.pack Update',
			action = pack_update(),
		},
	}

	if #vim.pack.get(nil, { info = false }) > 0 then
		table.insert(items, {
			key = 's',
			icon = '󰑐 ',
			desc = 'vim.pack Sync',
			action = pack_update { target = 'lockfile' },
		})
	end

	vim.list_extend(items, {
		{
			key = 'l',
			icon = '󰏖 ',
			desc = 'vim.pack List',
			action = pack_update { offline = true },
		},
		{
			key = 't',
			icon = ' ',
			desc = 'Git Todo',
			action = edit_file '.git/todo.md',
		},
		{
			key = 'q',
			icon = ' ',
			desc = 'Quit',
			action = function()
				vim.cmd.quitall()
			end,
		},
	})

	return items
end

local function recent_file_items(opts, next_key)
	local root = opts.cwd
		and vim.fs.normalize(opts.cwd == true and vim.fn.getcwd() or opts.cwd)
	local filter_map = root and { [root] = true } or nil
	local ret = {}

	for _, file in ipairs(oldfiles(filter_map)) do
		if not opts.filter or opts.filter(file) then
			table.insert(ret, {
				key = next_key(),
				icon = 'file',
				file = file,
				desc = vim.fn.fnamemodify(file, ':t'),
				action = edit_file(file),
			})

			if #ret >= (opts.limit or 5) then
				break
			end
		end
	end

	return ret
end

local function project_items(next_key)
	local dirs = {}

	for _, file in ipairs(oldfiles()) do
		local dir = get_git_root(file)
		if dir and not vim.tbl_contains(dirs, dir) then
			table.insert(dirs, dir)
			if #dirs >= 5 then
				break
			end
		end
	end

	return vim.tbl_map(function(dir)
		return {
			key = next_key(),
			icon = 'directory',
			file = dir,
			desc = vim.fn.fnamemodify(dir, ':t'),
			action = function()
				vim.fn.chdir(dir)
				read_session_or_pick()
			end,
		}
	end, dirs)
end

local function path_units(file, path_width)
	local fname = vim.fn.fnamemodify(file, ':~')
	if #fname > path_width then
		fname = vim.fn.pathshorten(fname)
	end

	if #fname > path_width then
		local dir, file_name = fname:match '^(.*)/(.+)$'
		if dir and file_name then
			file_name = file_name:sub(-(path_width - #dir - 2))
			fname = dir .. '/…' .. file_name
		end
	end

	local dir, file_name = fname:match '^(.*)/(.+)$'
	if dir and file_name then
		return {
			unit(dir .. '/', 'MiniStarterDashboardDir'),
			unit(file_name, 'MiniStarterDashboardFile'),
		}
	end

	return { unit(fname, 'MiniStarterDashboardFile') }
end

local function add_title(lines, title, file)
	local line = { unit(title, 'MiniStarterDashboardTitle') }
	if file then
		vim.list_extend(line, path_units(file, width))
	end
	add_line(lines, line)
	add_blank(lines, 1)
end

local function add_header(lines)
	for _, text in ipairs(header) do
		local line = { unit(text, 'MiniStarterDashboardHeader') }
		local left = math.max(math.floor((width - line_width(line)) / 2), 0)
		if left > 0 then
			table.insert(line, 1, unit((' '):rep(left)))
		end
		add_line(lines, line)
	end
	add_blank(lines, 2)
end

local function add_quote(lines)
	for _, line in ipairs(quote) do
		if line == '' then
			add_blank(lines, 1)
		else
			local hl = line:match '^—' and 'MiniStarterDashboardAuthor'
				or 'MiniStarterDashboardQuote'
			for _, wrapped_line in ipairs(wrap_text(line)) do
				add_line(lines, { unit(wrapped_line, hl) })
			end
		end
	end
	add_blank(lines, 2)
end

local function add_action(lines, item)
	local icon_text, icon_hl = item.icon, 'MiniStarterDashboardIcon'
	if item.icon == 'file' or item.icon == 'directory' then
		icon_text, icon_hl = icon(item.file, item.icon)
	end

	local left = pad_right({ unit(icon_text, icon_hl) }, 2)
	table.insert(left, unit ' ')

	local right = { unit(' ' .. item.key, 'MiniStarterDashboardKey') }
	local center_width = width - line_width(left) - line_width(right)
	local center = item.file and path_units(item.file, center_width)
		or { unit(item.desc, 'MiniStarterDashboardFile') }

	item.name = item.desc
	center[#center].type = 'item'
	center[#center].item = item
	pad_right(center, center_width)

	local line = {}
	vim.list_extend(line, left)
	vim.list_extend(line, center)
	vim.list_extend(line, right)
	add_line(lines, line)
end

local function add_actions(lines, items, action_items)
	for _, item in ipairs(items) do
		table.insert(action_items, item)
		add_action(lines, item)
	end
	if #items > 0 then
		add_blank(lines, 1)
	end
end

local function apply_window_padding(lines, buf_id)
	local win = vim.fn.bufwinid(buf_id)
	local win_width = win > 0 and vim.api.nvim_win_get_width(win) or vim.o.columns
	local win_height = win > 0 and vim.api.nvim_win_get_height(win) or vim.o.lines
	win_height = win_height + (vim.o.laststatus >= 2 and 1 or 0)

	local left = math.max(math.floor((win_width - width) / 2), 0)
	local top = math.max(math.floor((win_height - #lines) / 2), 0)

	for _, line in ipairs(lines) do
		local line_left = left
		local overflow = line_width(line) - width
		if overflow > 0 then
			line_left = line_left - math.floor(overflow / 2)
		end
		table.insert(line, 1, unit((' '):rep(math.max(line_left, 0))))
	end

	for _ = 1, top do
		table.insert(lines, 1, { unit '' })
	end
end

local function map_action_keys(buf, items)
	local keys = {}
	for _, item in ipairs(items) do
		keys[item.key] = true
		vim.keymap.set('n', item.key, item.action, {
			buffer = buf,
			nowait = true,
			silent = true,
			desc = 'Dashboard action',
		})
	end

	for key in pairs(vim.b[buf].starter_dashboard_keys or {}) do
		if not keys[key] then
			pcall(vim.keymap.del, 'n', key, { buffer = buf })
		end
	end
	vim.b[buf].starter_dashboard_keys = keys
end

local function render_dashboard(_, buf_id)
	local bookmarks = bookmark_items()
	local used_keys = {}
	for _, item in ipairs(bookmarks) do
		used_keys[item.key] = true
	end

	local next_key = next_autokey(used_keys)
	local cwd = uv.cwd()
	local lines = {}
	local action_items = {}

	add_header(lines)
	add_quote(lines)
	add_title(lines, 'Bookmarks')
	add_actions(lines, bookmarks, action_items)
	add_title(lines, 'MRU ', vim.fn.fnamemodify('.', ':~'))
	add_actions(
		lines,
		recent_file_items(
			{ cwd = true, limit = 8, filter = filter_common },
			next_key
		),
		action_items
	)
	add_title(lines, 'MRU')
	add_actions(
		lines,
		recent_file_items({
			limit = 8,
			filter = function(file)
				return file:find(cwd, 1, true) == nil and filter_common(file)
			end,
		}, next_key),
		action_items
	)
	add_title(lines, 'Sessions')
	add_actions(lines, project_items(next_key), action_items)

	apply_window_padding(lines, buf_id)
	map_action_keys(buf_id, action_items)
	return lines
end

local M = {}

M.content_hook = render_dashboard

return M
