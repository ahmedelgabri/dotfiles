-- The block's own child is `login`, which reports no cwd, so callers look at
-- the foreground process, as tmux does. Errors are ignored and give `nil`, so
-- a block that is not a terminal is treated as running nothing.
local function foreground(block_id)
	local p = rex.block.call(
		'com.superlogical.terminal',
		'process',
		{ block_id = block_id }
	)
	return p and p.foreground
end

-- Like tmux's `#{pane_current_path}`; `nil` makes the new tab start in `$HOME`.
local function block_cwd(block_id)
	local fg = foreground(block_id)
	return fg and fg.cwd
end

-- Rex always appends new windows to the end of the tab order, and
-- `client.tab.new` takes no position argument, so open the tab and then move
-- it before the tab that followed the current one.
local function new_tab_next(ctx)
	local view, err = rex.session.view {}
	if err ~= nil then
		error(err, 0)
	end

	local after, cwd
	for i, w in ipairs(view.windows) do
		if w.window_id == view.active_window_id then
			after = view.windows[i + 1]
			cwd = block_cwd(w.focused_block_id)
			break
		end
	end

	local w, err = rex.session.new_window {
		layout = rex.layout.block {
			flavor = 'com.superlogical.terminal.shell',
			options = { cwd = cwd },
		},
	}
	if err ~= nil then
		error(err, 0)
	end

	-- With no tab after the current one, the default append is already right.
	if after ~= nil then
		local _, err = rex.session.move_window {
			window_id = w.window_id,
			before_window_id = after.window_id,
		}
		if err ~= nil then
			error(err, 0)
		end
	end

	-- The app keeps showing its own selected tab even when the server makes
	-- the new window active, so ask the app to select it.
	rex.client.queue('session.select', {
		session_id = ctx.session_id,
		window_id = w.window_id,
	})
	return { window_id = w.window_id }
end

rex.action {
	name = 'tab_new_next',
	title = 'New Tab Next to Current',
	run = function(ctx, args)
		return new_tab_next(ctx)
	end,
}

rex.bind('cmd+t', 'tab_new_next')
