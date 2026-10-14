-- Windows rx appends to every new session, after the definition's own
-- windows. Rex cannot show one window in several sessions the way tmux
-- link-window does, so each session gets its own copies.
local shell = 'com.superlogical.terminal.shell'

-- The argument travels as $1 so it never needs shell quoting.
local function sh_ok(script, arg)
	return rex.exec({ 'sh', '-c', script, 'sh', arg }).ok
end

local function has(cmd)
	return sh_ok('command -v "$1"', cmd)
end

local function dir(name)
	local path = os.getenv(name)
	if path ~= nil and path ~= '' and sh_ok('test -d "$1"', path) then
		return path
	end
end

local function term(options)
	return rex.layout.block { flavor = shell, options = options }
end

-- Typed rather than exec'd, like mx-init's send-keys, so the pane falls back
-- to a shell when the program exits.
local function typed(command, cwd)
	return term { cwd = cwd, initial_input = command .. '\n' }
end

local editor = os.getenv 'EDITOR' or 'vi'
local windows = {}

for _, app in ipairs {
	{ 'mail', 'aerc' },
	{ 'rss', 'newsraft' },
	{ 'HN', 'clx' },
} do
	if has(app[2]) then
		table.insert(windows, { label = app[1], layout = typed(app[2]) })
	end
end

local dotfiles = dir 'DOTFILES'
if dotfiles then
	table.insert(windows, {
		label = 'dotfiles',
		layout = rex.layout.horizontal(
			0.5,
			typed(editor, dotfiles),
			term { cwd = dotfiles }
		),
	})
end

local notes = dir 'NOTES_DIR'
if notes then
	table.insert(windows, { label = 'notes', layout = typed(editor, notes) })
end

return windows
