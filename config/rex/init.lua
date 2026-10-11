-- ██████╗ ███████╗██╗  ██╗                   __
-- ██╔══██╗██╔════╝╚██╗██╔╝                  / _)
-- ██████╔╝█████╗   ╚███╔╝          _.----._/ /
-- ██╔══██╗██╔══╝   ██╔██╗         /         /
-- ██║  ██║███████╗██╔╝ ██╗     __/ (  | (  |
-- ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    /__.-'|_|--|_|
--
-- Keys, actions and popups for Rex, ported from config/tmux/tmux.conf.

-- =======================================================================
-- = Helpers
-- =======================================================================

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

-- The same programs as `VIM_PATTERN` in config/tmux/tmux.conf. fzf is one of
-- them because it moves its cursor with ctrl+j and ctrl+k.
local function runs_vim(block_id)
	local fg = foreground(block_id)
	if fg == nil then
		return false
	end
	local name = fg.name:gsub('^%.', ''):gsub('%-wrapped$', ''):gsub('diff$', '')
	return name:match '^g?view$' ~= nil
		or name:match '^g?l?n?vim?x?$' ~= nil
		or name == 'fzf'
end

-- Wraps to the far side at the edge, like tmux's `select-pane`.
local function focus_pane(direction)
	rex.session.focus_direction { direction = direction, wrap = true }
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

-- Like tmux's `display-popup -E`: a centred floating terminal in the current
-- pane's directory that closes when its program exits.
local function open_popup(ctx, width, height, command)
	local _, err = rex.session.new_layer {
		bounds = { (1 - width) / 2, (1 - height) / 2, width, height },
		focus = true,
		layout = rex.layout.block {
			flavor = 'com.superlogical.terminal.shell',
			options = { cwd = block_cwd(ctx.block_id), command = command },
		},
	}
	if err ~= nil then
		error(err, 0)
	end
end

-- =======================================================================
-- = Actions
-- =======================================================================

rex.action {
	name = 'tab_new_next',
	title = 'New Tab Next to Current',
	run = function(ctx, args)
		return new_tab_next(ctx)
	end,
}

-- What nvim calls at the edge of the editor. It keeps a zoomed nvim in place,
-- like `disable_when_zoomed` does for nvim-tmux-navigation, because
-- `focus_direction` would unzoom it.
rex.action {
	name = 'pane_focus_unless_zoomed',
	title = 'Focus Pane Unless Zoomed',
	args = { direction = 'string' },
	run = function(ctx, args)
		local view, err = rex.session.view {}
		if err ~= nil then
			error(err, 0)
		end
		for _, w in ipairs(view.windows) do
			if w.window_id == view.active_window_id and w.zoomed_block_id then
				return
			end
		end
		focus_pane(args.direction)
	end,
}

-- tmux keeps a `bind -r` key live for a moment after the prefix. Rex has no
-- such timeout, so the first resize enters a mode where the arrows keep
-- resizing until Escape or Enter. It is exclusive so that stray keys don't
-- reach the terminal while it is easy to forget the mode is on.
rex.mode('resize', { exclusive = true })

rex.action {
	name = 'pane_resize_repeat',
	title = 'Resize Pane Repeatedly',
	args = { direction = 'string' },
	run = function(ctx, args)
		rex.client.queue('pane.resize', { direction = args.direction })
		rex.client.queue('client.mode.enter', { name = 'resize' })
	end,
}

rex.action {
	name = 'popup_shell',
	title = 'Popup Shell',
	run = function(ctx, args)
		open_popup(ctx, 0.75, 0.75)
	end,
}

rex.action {
	name = 'popup_mx_pick',
	title = 'Pick Project or Session',
	run = function(ctx, args)
		open_popup(ctx, 0.7, 0.7, { 'mx', '--pick' })
	end,
}

-- Like tmux's `confirm-before kill-session`. Lua has no way to ask, so a small
-- popup does, and `read -k 1` takes the answer without Enter.
rex.action {
	name = 'session_kill_confirm',
	title = 'Kill Session…',
	run = function(ctx, args)
		local view, err = rex.session.view {}
		if err ~= nil then
			error(err, 0)
		end
		open_popup(ctx, 0.4, 0.1, {
			'zsh',
			'-fc',
			'printf "\\e[31;49m\\e[2J\\e[H kill-session %s? (y/n) " "$1"; read -k 1 answer; [[ $answer == y ]] && rex kill "$2"',
			'session_kill_confirm',
			view.label or ctx.session_id,
			ctx.session_id,
		})
	end,
}

-- A stand-in for tmux's copy mode until Rex ships a native one. It opens the
-- focused pane's text (screen plus scrollback) read-only in a full-window
-- floating pane running a bare nvim (-u NONE, no plugins or colorscheme),
-- scrolled to the bottom so it matches the pane.
--
--   v / V    start a selection (normal vim motions and / search work)
--   y        any yank (y in visual mode, yy, yiw, ...) copies to the
--            clipboard and closes
--   q        close without copying
--
-- Source: https://gist.github.com/catsby/0fd3d65ae905ee645a5e7de89b17b5df
rex.action {
	name = 'copy_mode',
	title = 'Copy Mode',
	description = "Open the focused pane's text in nvim to select and copy it.",
	run = function(ctx)
		if not ctx.block_id then
			error('copy_mode: no focused pane', 0)
		end

		local r, err = rex.block.call(
			'com.superlogical.terminal',
			'format',
			{ block_id = ctx.block_id, format = 'text', trim = true }
		)
		if not r then
			error(err, 0)
		end

		local text = r.content:gsub('%s+$', '') .. '\n'
		local path = os.tmpname()
		local f = assert(io.open(path, 'w'))
		f:write(text)
		f:close()

		local vim_cmds = table.concat({
			'set clipboard=unnamedplus nomodifiable readonly',
			'nnoremap <silent> q :qa!<CR>',
			"execute 'normal! Gzb'",
			"autocmd TextYankPost * call timer_start(0, {-> execute('qa!')})",
		}, ' | ')

		local layer, err2 = rex.session.new_layer {
			bounds = { 0, 0, 1, 1 },
			focus = true,
			layout = rex.layout.block {
				flavor = 'com.superlogical.terminal.shell',
				options = {
					command = {
						'/bin/sh',
						'-c',
						-- Closing the layer doesn't return focus to the pane it came
						-- from, so focus that pane before the layer goes away.
						[[trap 'rm -f "$1"' EXIT; nvim -u NONE -i NONE -n -c "$2" "$1"; ]]
							.. [[rex focus -s "$4" "$3" >/dev/null 2>&1]],
						'copy_mode',
						path,
						vim_cmds,
						ctx.block_id,
						ctx.session_id,
					},
				},
			},
		}
		if not layer then
			os.remove(path)
			error(err2, 0)
		end
		return layer
	end,
}

-- =======================================================================
-- = Key Bindings — General
-- =======================================================================

rex.bind('cmd+t', 'tab_new_next')
rex.bind('ctrl+space', 'client.palette.toggle')

-- =======================================================================
-- = Key Bindings — Navigation
-- =======================================================================

-- Like vim-tmux-navigator: in vim the key goes to the editor, which moves
-- between its own windows and hands back to Rex at its edge (see
-- config/nvim/plugin/core.lua). Returning false sends the key to the block.
for key, direction in pairs { h = 'left', j = 'down', k = 'up', l = 'right' } do
	rex.bind('ctrl+' .. key, function(ctx)
		if runs_vim(ctx.block_id) then
			return false
		end
		focus_pane(direction)
		return true
	end)
end

rex.bind('shift+left', 'client.tab.previous')
rex.bind('shift+right', 'client.tab.next')
rex.bind('ctrl+shift+left', 'client.tab.move.backward')
rex.bind('ctrl+shift+right', 'client.tab.move.forward')

-- =======================================================================
-- = Key Bindings — Prefix
-- =======================================================================

-- The tmux prefix, so the same keys work in config/tmux/tmux.conf and here.
local prefix = 'ctrl+a>'

rex.bind(prefix .. 'ctrl+a', 'pane.send_key', { key = 'ctrl+a' })
rex.bind(prefix .. 'r', 'client.config.reload')
rex.bind(prefix .. 'ctrl+q', 'session_kill_confirm')

-- Tabs & panes
rex.bind(prefix .. 'c', 'tab_new_next')
rex.bind(prefix .. 'v', 'pane.split', { direction = 'right' })
rex.bind(prefix .. 's', 'pane.split', { direction = 'down' })
rex.bind(prefix .. 'x', 'pane.close')
rex.bind(prefix .. 'z', 'pane.zoom')
rex.bind(prefix .. 'b', 'pane.move_to_new_tab')
rex.bind(prefix .. '[', 'copy_mode')

-- Resizing
for _, direction in ipairs { 'left', 'right', 'up', 'down' } do
	rex.bind(prefix .. direction, 'pane_resize_repeat', { direction = direction })
	rex.bind('resize/' .. direction, 'pane.resize', { direction = direction })
end
rex.bind('resize/enter', 'client.mode.exit')

-- Popups
rex.bind(prefix .. 't', 'popup_shell')
rex.bind(prefix .. 'g', 'popup_mx_pick')
