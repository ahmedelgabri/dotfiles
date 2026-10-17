-- Windows mx adds to every new session, after the definition's own windows.
-- tmux links them from one `_shared` session; Rex cannot show one window in
-- several sessions, so each Rex session gets its own copies.
local editor = os.getenv 'EDITOR' or 'vi'
local windows = {}

for _, app in ipairs {
	{ 'mail', 'aerc' },
	{ 'rss', 'newsraft' },
	{ 'HN', 'clx' },
} do
	if mx.has(app[2]) then
		table.insert(windows, { label = app[1], layout = { command = app[2] } })
	end
end

local dotfiles = os.getenv 'DOTFILES'
if mx.isdir(dotfiles) then
	table.insert(windows, {
		label = 'dotfiles',
		layout = {
			split = 'horizontal',
			ratio = 0.5,
			{ cwd = dotfiles, command = editor },
			{ cwd = dotfiles },
		},
	})
end

local notes = os.getenv 'NOTES_DIR'
if mx.isdir(notes) then
	table.insert(windows, {
		label = 'notes',
		layout = { cwd = notes, command = editor },
	})
end

return { windows = windows }
