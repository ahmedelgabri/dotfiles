-- The Rex backend of mx, run inside `rex do`. Inputs travel as environment
-- variables because `rex do key=value` args guess types: a session named
-- "true" or "1" would not arrive as a string.
--
--   MX_ACTION=open    find the session labeled MX_NAME, or create it from
--                     MX_DEF (may be empty) and MX_SHARED; returns
--                     "<id> existing" or "<id> created"
--   MX_ACTION=finish  (with -s) refill a session left with no windows, then
--                     focus the definition's panes
--   MX_ACTION=export  (with -s) print a definition for the session

local lib = dofile(os.getenv 'MX_LUA_DIR' .. '/lib.lua')

local SHELL = 'com.superlogical.terminal.shell'
local TERMINAL = 'com.superlogical.terminal'

-- Rex returns nil, not "", for an empty environment variable.
local function env(name)
	local value = os.getenv(name)
	if value ~= '' then
		return value
	end
end

local function call(method, args)
	local result, err = rex.call(method, args)
	if err ~= nil then
		error(method .. ': ' .. err, 0)
	end
	return result
end

-- rex.session methods act on the session `rex do -s` attached to.
local function session(method, args)
	local result, err = rex.session[method](args)
	if err ~= nil then
		error('session.' .. method .. ': ' .. err, 0)
	end
	return result
end

local function exists(path)
	local f = path and io.open(path)
	if f ~= nil then
		f:close()
		return true
	end
end

-- Definition windows, then shared ones, as normalized trees.
local function windows()
	local root = env 'MX_ROOT'
	local def = lib.plain(root)
	if env 'MX_DEF' then
		def = lib.load(env 'MX_DEF', root)
	end
	local out = lib.windows(def)
	if exists(env 'MX_SHARED') then
		for _, w in ipairs(lib.load(env 'MX_SHARED', def.root).windows) do
			table.insert(out, w)
		end
	end
	return out
end

local function to_rex(node)
	if node.split then
		return rex.layout[node.split](node.ratio, to_rex(node[1]), to_rex(node[2]))
	end
	local options = { cwd = node.cwd }
	if node.command ~= nil then
		options.initial_input = node.command .. '\n'
	end
	return rex.layout.block { flavor = SHELL, options = options }
end

local function tiled(w)
	for _, layer in ipairs(w.layers or {}) do
		if layer.kind == 'tiled' then
			return layer.layout
		end
	end
end

local function blocks(node, out)
	out = out or {}
	if node.split then
		blocks(node.split.before, out)
		blocks(node.split.after, out)
	else
		table.insert(out, node.block_id)
	end
	return out
end

local actions = {}

-- Rex allows duplicate labels, so the lookup must come before
-- session.create. Every window is built in one call, so a definition that
-- fails creates nothing.
function actions.open()
	local name = env 'MX_NAME'
	for _, s in ipairs(call('session.list').sessions or {}) do
		if s.label == name then
			return s.session_id .. ' existing'
		end
	end
	local initial = {}
	for _, w in ipairs(windows()) do
		table.insert(initial, { window_label = w.label, layout = to_rex(w.layout) })
	end
	local created =
		call('session.create', { label = name, initial_windows = initial })
	return created.session_id .. ' created'
end

-- session.view and session.focus_block only reach the session `rex do -s`
-- attached to, which is why this runs separately from open.
function actions.finish()
	local view = session('view', {})
	if #(view.windows or {}) > 0 and env 'MX_CREATED' == nil then
		return
	end
	local wanted = windows()
	if #(view.windows or {}) == 0 then
		for _, w in ipairs(wanted) do
			session('new_window', {
				window_label = w.label,
				layout = to_rex(w.layout),
				focus = false,
			})
		end
		view = session('view', {})
	end
	-- Focusing a block also activates its window, so going backwards leaves
	-- the first window active.
	for i = #view.windows, 1, -1 do
		local ids = blocks(tiled(view.windows[i]))
		local focus = wanted[i] and lib.focus(lib.panes(wanted[i].layout)) or 1
		session('focus_block', { block_id = ids[focus] })
	end
end

-- Rex reports only a process's name, so exact commands come from the zsh
-- hook's files. The block running this export is skipped so `mx --export`
-- does not replay itself.
function actions.export()
	local view = session('view', {})
	local skip = {}
	if exists(env 'MX_SHARED') then
		for _, w in ipairs(lib.load(env 'MX_SHARED', os.getenv 'HOME').windows) do
			if w.label ~= nil then
				skip[w.label] = true
			end
		end
	end
	local self = env 'MX_SELF'

	local function pane(id, focused)
		local p = rex.block.call(TERMINAL, 'process', { block_id = id })
		local fg = (p or {}).foreground or {}
		local command
		if id ~= self then
			local f = io.open(env 'MX_COMMANDS' .. '/' .. id)
			if f ~= nil then
				command = f:read('*a'):gsub('\n$', '')
				f:close()
				if command == '' then
					command = nil
				end
			end
		end
		return {
			cwd = fg.cwd,
			command = command,
			focus = id == focused,
			process = command == nil and lib.program(fg.argv0) or nil,
		}
	end

	local function tree(node, focused)
		if node.split then
			return {
				split = node.split.direction,
				ratio = node.split.ratio,
				tree(node.split.before, focused),
				tree(node.split.after, focused),
			}
		end
		return pane(node.block_id, focused)
	end

	local out = {}
	for _, w in ipairs(view.windows or {}) do
		local layout = tiled(w)
		if layout ~= nil and not skip[w.label] then
			local floating = #(w.layers or {}) - 1
			local node = tree(layout, w.focused_block_id)
			lib.panes(node)[1].focus = false
			table.insert(out, {
				label = w.label ~= '' and w.label or nil,
				layout = node,
				note = floating > 0 and (floating .. ' floating layer(s) not exported')
					or nil,
			})
		end
	end
	if #out == 0 then
		error('session has no windows to export', 0)
	end
	local root = lib.panes(out[1].layout)[1].cwd or os.getenv 'HOME'
	io.write(
		lib.serialize(
			lib.exported(view.label or view.session_id),
			root,
			out,
			os.getenv 'HOME'
		)
	)
end

return actions[env 'MX_ACTION']()
