local root = assert(arg[1], 'pass the repository root')
local terminal = 'com.superlogical.terminal'

local function equal(what, actual, expected)
	assert(
		actual == expected,
		what .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected)
	)
end

-- Loads config/rex/init.lua against a fake `rex`. `state.names` maps block IDs
-- to foreground process names and `state.cwds` to their directories; a block
-- in neither is not a terminal, so its `process` call fails.
local function load(state)
	state.names = state.names or {}
	state.cwds = state.cwds or {}
	local fake = { binds = {}, actions = {}, calls = {} }
	local function record(...)
		table.insert(fake.calls, { ... })
	end
	rex = {
		bind = function(key, target)
			fake.binds[key] = target
		end,
		action = function(def)
			fake.actions[def.name] = def
		end,
		layout = {
			block = function(spec)
				return { block = spec }
			end,
		},
		block = {
			call = function(creator, method, args)
				record('block.call', creator, method, args.block_id)
				local name = state.names[args.block_id]
				local cwd = state.cwds[args.block_id]
				if name == nil and cwd == nil then
					return nil, 'not a terminal'
				end
				return { foreground = { name = name or 'zsh', cwd = cwd } }
			end,
		},
		session = {
			view = function()
				if state.view_error then
					return nil, state.view_error
				end
				return state.view
			end,
			focus_direction = function(args)
				record('focus_direction', args.direction, args.wrap)
				return { revision = 1 }
			end,
			new_window = function(args)
				record('new_window', args.layout.block)
				if state.new_window_error then
					return nil, state.new_window_error
				end
				return { window_id = 'window:new' }
			end,
			move_window = function(args)
				record('move_window', args.window_id, args.before_window_id)
				return { revision = 1 }
			end,
		},
		client = {
			queue = function(name, args)
				record('queue', name, args.session_id, args.window_id)
			end,
		},
	}
	-- Stays global: the functions init.lua binds look `rex` up when they run.
	dofile(root .. '/config/rex/init.lua')
	return fake
end

local function calls_named(fake, name)
	local found = {}
	for _, call in ipairs(fake.calls) do
		if call[1] == name then
			table.insert(found, call)
		end
	end
	return found
end

local function window(id, focused, zoomed)
	return { window_id = id, focused_block_id = focused, zoomed_block_id = zoomed }
end

local directions = { h = 'left', j = 'down', k = 'up', l = 'right' }

-- Keymap
do
	local fake = load {}
	equal('cmd+t', fake.binds['cmd+t'], 'tab_new_next')
	for key in pairs(directions) do
		equal('ctrl+' .. key, type(fake.binds['ctrl+' .. key]), 'function')
	end
	assert(fake.actions.tab_new_next, 'tab_new_next action')
	assert(fake.actions.pane_focus_unless_zoomed, 'pane_focus_unless_zoomed')
end

-- The keys go to the block for the programs tmux's VIM_PATTERN matches,
-- including Nix wrappers such as .nvim-wrapped.
for _, name in ipairs {
	'vi',
	'vim',
	'nvim',
	'lvim',
	'vimx',
	'gvim',
	'view',
	'gview',
	'vimdiff',
	'nvimdiff',
	'fzf',
	'.nvim-wrapped',
	'nvim-wrapped',
} do
	for key in pairs(directions) do
		local fake = load { names = { ['block:a'] = name } }
		local handled = fake.binds['ctrl+' .. key]({ block_id = 'block:a' }, {})
		equal(name .. ' ctrl+' .. key .. ' handled', handled, false)
		equal(name .. ' focus calls', #calls_named(fake, 'focus_direction'), 0)
	end
end

-- Every other program, and a block that is not a terminal, moves Rex focus.
local not_vim = {
	zsh = 'block:a',
	['-zsh'] = 'block:a',
	['.claude-wrapped'] = 'block:a',
	pi = 'block:a',
	less = 'block:a',
	preview = 'block:a',
	envim = 'block:a',
	fzfx = 'block:a',
	vimmer = 'block:a',
	['not a terminal'] = 'block:other',
}
for name, block in pairs(not_vim) do
	for key, direction in pairs(directions) do
		local fake = load { names = { ['block:a'] = name } }
		local handled = fake.binds['ctrl+' .. key]({ block_id = block }, {})
		local what = name .. ' ctrl+' .. key
		equal(what .. ' handled', handled, true)
		local focus = calls_named(fake, 'focus_direction')
		equal(what .. ' focus calls', #focus, 1)
		equal(what .. ' direction', focus[1][2], direction)
		equal(what .. ' wraps', focus[1][3], true)
		local lookup = calls_named(fake, 'block.call')[1]
		equal(what .. ' creator', lookup[2], terminal)
		equal(what .. ' method', lookup[3], 'process')
		equal(what .. ' block', lookup[4], block)
	end
end

-- pane_focus_unless_zoomed
do
	local run = function(state, direction)
		local fake = load(state)
		fake.actions.pane_focus_unless_zoomed.run(
			{ session_id = 'session:s' },
			{ direction = direction }
		)
		return calls_named(fake, 'focus_direction')
	end

	local focus = run({
		view = {
			active_window_id = 'window:1',
			windows = { window('window:1', 'block:a') },
		},
	}, 'up')
	equal('unzoomed focus calls', #focus, 1)
	equal('unzoomed direction', focus[1][2], 'up')
	equal('unzoomed wraps', focus[1][3], true)

	focus = run({
		view = {
			active_window_id = 'window:1',
			windows = { window('window:1', 'block:a', 'block:a') },
		},
	}, 'left')
	equal('zoomed focus calls', #focus, 0)

	-- Only the active window's zoom matters.
	focus = run({
		view = {
			active_window_id = 'window:1',
			windows = {
				window('window:1', 'block:a'),
				window('window:2', 'block:b', 'block:b'),
			},
		},
	}, 'right')
	equal('other window zoomed focus calls', #focus, 1)

	local ok, err = pcall(run, { view_error = 'view failed' }, 'down')
	equal('view error raised', ok, false)
	equal('view error message', err, 'view failed')
end

-- tab_new_next
do
	local function run(state)
		local fake = load(state)
		local result = fake.actions.tab_new_next.run(
			{ session_id = 'session:s' },
			{}
		)
		return fake, result
	end

	local three = {
		active_window_id = 'window:1',
		windows = {
			window('window:0', 'block:z'),
			window('window:1', 'block:a'),
			window('window:2', 'block:b'),
		},
	}

	local fake, result = run {
		view = three,
		cwds = { ['block:a'] = '/tmp/work dir', ['block:b'] = '/elsewhere' },
	}
	local created = calls_named(fake, 'new_window')
	equal('new windows', #created, 1)
	equal('flavor', created[1][2].flavor, terminal .. '.shell')
	equal('cwd from the current tab', created[1][2].options.cwd, '/tmp/work dir')
	local moved = calls_named(fake, 'move_window')
	equal('moves', #moved, 1)
	equal('moved window', moved[1][2], 'window:new')
	equal('moved before the next tab', moved[1][3], 'window:2')
	local queued = calls_named(fake, 'queue')
	equal('queued', #queued, 1)
	equal('queued action', queued[1][2], 'session.select')
	equal('queued session', queued[1][3], 'session:s')
	equal('queued window', queued[1][4], 'window:new')
	equal('result', result.window_id, 'window:new')

	-- The last tab needs no move.
	fake = run {
		view = {
			active_window_id = 'window:2',
			windows = three.windows,
		},
		cwds = { ['block:b'] = '/elsewhere' },
	}
	equal(
		'last tab cwd',
		calls_named(fake, 'new_window')[1][2].options.cwd,
		'/elsewhere'
	)
	equal('last tab moves', #calls_named(fake, 'move_window'), 0)

	-- Without a cwd the new tab starts in Rex's default, $HOME.
	fake = run { view = three }
	equal('no cwd', calls_named(fake, 'new_window')[1][2].options.cwd, nil)

	local ok, err = pcall(run, { view = three, new_window_error = 'too many' })
	equal('new_window error raised', ok, false)
	equal('new_window error message', err, 'too many')
	ok, err = pcall(run, { view_error = 'view failed' })
	equal('tab view error raised', ok, false)
	equal('tab view error message', err, 'view failed')
end

print 'rex init.lua: ok'
