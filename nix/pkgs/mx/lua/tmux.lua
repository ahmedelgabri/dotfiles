-- The tmux backend of mx, run with LuaJIT:
--
--   tmux.lua open <session> <definition or ""> <root>
--   tmux.lua shared <shared.lua>
--   tmux.lua export <session> <commands dir> [<migrated definition>]
--
-- Errors go to stderr as "mx: <message>" with exit status 1.

local dir = arg[0]:match '^(.*)/' or '.'
local lib = dofile(dir .. '/lib.lua')

local function quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Runs one tmux invocation; `;` entries separate commands, so a whole window
-- is built in a single call.
local function tmux(args)
	local cmd = {}
	for _, a in ipairs(args) do
		table.insert(cmd, a == ';' and '\\;' or quote(a))
	end
	-- LuaJIT's popen close returns true even when the command failed, so the
	-- shell appends the exit status as the last line.
	local p =
		assert(io.popen('tmux ' .. table.concat(cmd, ' ') .. ' 2>&1; echo "$?"'))
	local out = p:read '*a'
	p:close()
	local status
	out, status = out:match '^(.-)(%d+)\n$'
	if status ~= '0' then
		error('tmux: ' .. out:gsub('\n$', ''), 0)
	end
	return out
end

-- Adds one tmux command to a chain, with the `;` that separates commands.
local function command(chain, ...)
	if #chain > 0 then
		table.insert(chain, ';')
	end
	for _, v in ipairs { ... } do
		table.insert(chain, v)
	end
end

-- tmux layout strings ----------------------------------------------------------

-- Splits keep one cell for the border between their two sides.
local function sizes(total, ratio)
	local first = math.floor((total - 1) * ratio + 0.5)
	first = math.max(1, math.min(total - 2, first))
	return first, total - 1 - first
end

-- Returns the cell string for node and, for a split, its direction and child
-- cells. Nested splits in one direction are merged into one tmux cell, which
-- is how tmux itself stores three panes side by side.
local function cell(node, x, y, w, h, ids)
	if not node.split then
		ids.n = ids.n + 1
		return string.format('%dx%d,%d,%d,%d', w, h, x, y, ids.n)
	end
	local items = {}
	local function add(child, cx, cy, cw, ch)
		local s, d, inner = cell(child, cx, cy, cw, ch, ids)
		if d == node.split then
			for _, i in ipairs(inner) do
				table.insert(items, i)
			end
		else
			table.insert(items, s)
		end
	end
	if node.split == 'horizontal' then
		local a, b = sizes(w, node.ratio)
		add(node[1], x, y, a, h)
		add(node[2], x + a + 1, y, b, h)
	else
		local a, b = sizes(h, node.ratio)
		add(node[1], x, y, w, a)
		add(node[2], x, y + a + 1, w, b)
	end
	local open, close = '{', '}'
	if node.split == 'vertical' then
		open, close = '[', ']'
	end
	local s = string.format('%dx%d,%d,%d', w, h, x, y)
		.. open
		.. table.concat(items, ',')
		.. close
	return s, node.split, items
end

-- tmux's layout_checksum: a 16-bit rotate-and-add over the layout text.
local function checksum(s)
	local sum = 0
	for i = 1, #s do
		sum = (math.floor(sum / 2) + (sum % 2) * 32768 + s:byte(i)) % 65536
	end
	return string.format('%04x', sum)
end

local function layout_string(node, w, h)
	local s = cell(node, 0, 0, w, h, { n = 0 })
	return checksum(s) .. ',' .. s
end

-- Open ---------------------------------------------------------------------------

-- Adds the commands that fill the window `target`, which already has its
-- first pane.
local function fill(args, target, layout, size, base)
	local panes = lib.panes(layout)
	for i, pane in ipairs(panes) do
		if i > 1 then
			-- Without -d the new pane becomes active, so every split and
			-- send-keys below lands on the newest pane, and panes keep tree
			-- order. Tiling after each split keeps room for the next one.
			command(args, 'split-window', '-t', target, '-c', pane.cwd)
			command(args, 'select-layout', '-t', target, 'tiled')
		end
		if pane.command ~= nil then
			command(args, 'send-keys', '-t', target, '-l', '--', pane.command)
			command(args, 'send-keys', '-t', target, 'Enter')
		end
	end
	if #panes > 1 then
		command(
			args,
			'select-layout',
			'-t',
			target,
			layout_string(layout, size.w, size.h)
		)
	end
	if #panes > 1 then
		command(
			args,
			'select-pane',
			'-t',
			target .. '.' .. (base + lib.focus(panes) - 1)
		)
	end
end

local function window_args(name, w, first)
	local args = { 'new-window', '-a', '-t', '=' .. name .. ':{end}' }
	if first then
		args = { 'new-session', '-d', '-s', name }
	end
	table.insert(args, '-c')
	table.insert(args, lib.panes(w.layout)[1].cwd)
	if w.label ~= nil then
		table.insert(args, '-n')
		table.insert(args, w.label)
	end
	return args
end

local function query_size(name)
	local out = tmux {
		'display-message',
		'-p',
		'-t',
		'=' .. name .. ':',
		'#{window_width} #{window_height} #{pane-base-index}',
	}
	local w, h, base = out:match '^(%d+) (%d+) (%d+)'
	return { w = tonumber(w), h = tonumber(h) }, tonumber(base)
end

-- Builds windows into session `name`. With `fresh`, the first window creates
-- the session; otherwise every window is appended. The size is only known
-- once the session exists, and the custom layout needs it.
local function build(name, windows, fresh)
	local size, base
	if not fresh then
		size, base = query_size(name)
	end
	for i, w in ipairs(windows) do
		local args = window_args(name, w, fresh and i == 1)
		if size == nil then
			tmux(args)
			size, base = query_size(name)
			args = {}
		end
		fill(args, '=' .. name .. ':{end}', w.layout, size, base)
		if #args > 0 then
			tmux(args)
		end
	end
end

local commands = {}

function commands.open(name, definition, root)
	local def = definition ~= '' and lib.load(definition, root) or lib.plain(root)
	build(name, lib.windows(def), true)
	tmux { 'select-window', '-t', '=' .. name .. ':^' }
end

-- _shared keeps the plain window it starts with; mx links every window after
-- it into each session.
function commands.shared(path)
	local def = lib.plain(os.getenv 'HOME')
	local f = io.open(path)
	if f ~= nil then
		f:close()
		def = lib.load(path, def.root)
	end
	tmux { 'new-session', '-d', '-s', '_shared', '-c', def.root }
	build('_shared', def.windows, false)
end

-- Export -------------------------------------------------------------------------

-- Decodes the JSON subset tmux writes for #{window_layout}: objects, arrays,
-- integers, true, and strings without escapes.
local function decode(s)
	local pos = 1
	local function value()
		local c = s:sub(pos, pos)
		if c == '{' or c == '[' then
			local t, close = {}, c == '{' and '}' or ']'
			pos = pos + 1
			while s:sub(pos, pos) ~= close do
				if c == '{' then
					local key = s:match('^"([^"]*)":', pos)
					assert(key, 'bad layout: ' .. s)
					pos = pos + #key + 3
					t[key] = value()
				else
					table.insert(t, value())
				end
				if s:sub(pos, pos) == ',' then
					pos = pos + 1
				end
			end
			pos = pos + 1
			return t
		end
		local str = s:match('^"([^"]*)"', pos)
		if str then
			pos = pos + #str + 2
			return str
		end
		if s:sub(pos, pos + 3) == 'true' then
			pos = pos + 4
			return true
		end
		local num = s:match('^-?%d+', pos)
		assert(num, 'bad layout: ' .. s)
		pos = pos + #num
		return tonumber(num)
	end
	return value()
end

-- Parses a decoded tmux layout cell into a binary tree whose leaves are pane
-- ids. 'h' cells are side by side, 'v' cells stacked; n children become a
-- chain of splits leaning right, each ratio from the cells' sizes. Floating
-- panes (those with a z-index) have no place in a definition, so they are
-- dropped.
local function parse(cell)
	local w, h = cell.w, cell.h
	if cell.t == 'p' then
		return { id = cell.I:sub(2), w = w, h = h }
	end
	local children = {}
	for _, child in ipairs(cell.c) do
		if child.z == nil then
			table.insert(children, parse(child))
		end
	end
	local split = cell.t == 'h' and 'horizontal' or 'vertical'
	local axis = split == 'horizontal' and 'w' or 'h'
	local function chain(i)
		if i == #children then
			return children[i]
		end
		local rest = chain(i + 1)
		local span = children[i][axis] + 1 + rest[axis]
		return {
			split = split,
			ratio = children[i][axis] / (span - 1),
			children[i],
			rest,
			w = split == 'horizontal' and span or w,
			h = split == 'vertical' and span or h,
		}
	end
	local node = chain(1)
	node.w, node.h = w, h
	return node
end

local function read_file(path)
	local f = io.open(path)
	if f == nil then
		return nil
	end
	local s = f:read '*a'
	f:close()
	s = s:gsub('\n$', '')
	if s ~= '' then
		return s
	end
end

function commands.export(name, commands_dir, migrated)
	-- tmux rejects control characters in window names, and the path comes
	-- last so a stray separator in it stays part of the path. -u keeps the
	-- separators: a client outside tmux with a non-UTF-8 locale gets control
	-- characters as '_'.
	local rows = tmux {
		'-u',
		'list-panes',
		'-s',
		'-t',
		'=' .. name,
		'-F',
		table.concat({
			'#{window_index}',
			'#{window_linked}',
			'#{window_layout}',
			'#{window_name}',
			'#{pid}',
			'#{pane_id}',
			'#{pane_active}',
			'#{pane_current_command}',
			'#{pane_current_path}',
		}, '\31'),
	}
	local windows, by_index, panes = {}, {}, {}
	local self = os.getenv 'TMUX_PANE'
	for row in rows:gmatch '[^\n]+' do
		local f = {}
		for field in (row .. '\31'):gmatch '(.-)\31' do
			table.insert(f, field)
		end
		local index, linked, layout, label, pid, id, active, process, path =
			unpack(f)
		if linked ~= '1' then
			if by_index[index] == nil then
				by_index[index] = { label = label, layout = layout }
				table.insert(windows, by_index[index])
			end
			-- The pane running mx --export would otherwise export its own
			-- invocation.
			local command
			if id ~= self then
				command = read_file(commands_dir .. '/tmux-' .. pid .. '-' .. id:sub(2))
			end
			panes[id:sub(2)] = {
				cwd = path,
				command = command,
				focus = active == '1',
				process = command == nil and lib.program(process) or nil,
			}
		end
	end
	if #windows == 0 then
		error('session has no unlinked windows: ' .. name, 0)
	end

	local function tree(node)
		if node.id then
			return panes[node.id]
		end
		return {
			split = node.split,
			ratio = node.ratio,
			tree(node[1]),
			tree(node[2]),
		}
	end
	for _, w in ipairs(windows) do
		w.layout = tree(parse(decode(w.layout).L))
	end
	for _, w in ipairs(windows) do
		lib.panes(w.layout)[1].focus = false
	end
	local root = lib.panes(windows[1].layout)[1].cwd
	local origin = migrated and lib.migrated(migrated) or lib.exported(name)
	io.write(lib.serialize(origin, root, windows, os.getenv 'HOME'))
end

local ok, err = pcall(commands[arg[1]], unpack(arg, 2))
if not ok then
	io.stderr:write('mx: ' .. tostring(err) .. '\n')
	os.exit(1)
end
