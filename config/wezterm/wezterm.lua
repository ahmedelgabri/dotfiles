local wezterm = require 'wezterm'
local mux = wezterm.mux

-- -- In newer versions of wezterm, use the config_builder which will
-- -- help provide clearer error messages
local config = wezterm.config_builder and wezterm.config_builder() or {}

-----------------------------------------------------------------------------
--- Helpers
----------------------------------------------------------------------------
local function is_dark()
	-- wezterm.gui is not always available, depending on what
	-- environment wezterm is operating in. Just return true
	-- if it's not defined.
	if wezterm.gui then
		-- Some systems report appearance like "Dark High Contrast"
		-- so let's just look for the string "Dark" and if we find
		-- it assume appearance is dark.
		return wezterm.gui.get_appearance():find 'Dark'
	end

	return true
end

local function theme_switcher(window, pane)
	-- get builtin color schemes
	local schemes = wezterm.get_builtin_color_schemes()
	local choices = {}

	-- populate theme names in choices list
	for key, _ in pairs(schemes) do
		table.insert(choices, { label = tostring(key) })
	end

	-- sort choices list
	table.sort(choices, function(c1, c2)
		return c1.label < c2.label
	end)

	window:perform_action(
		wezterm.action.InputSelector {
			title = '🎨 Pick a Theme!',
			choices = choices,
			fuzzy = true,

			action = wezterm.action_callback(function(inner_win, _, id, label)
				if not id and not label then
					wezterm.log_info 'cancelled'
				else
					inner_win:set_config_overrides { color_scheme = label }
				end
			end),
		},
		pane
	)
end

-----------------------------------------------------------------------------
--- Config
----------------------------------------------------------------------------

config.font = wezterm.font_with_fallback {
	{ family = 'PragmataPro Liga' },
	'Apple Color Emoji',
}
config.font_size = 12.0
config.front_end = 'WebGpu'
config.freetype_load_flags = 'NO_HINTING'
-- config.freetype_load_target = 'HorizontalLcd'
-- config.freetype_render_target = 'HorizontalLcd'

-- NOTE: Not sure I like this or not, let's try
config.window_background_opacity = 0.99
config.macos_window_background_blur = 30
--
-- config.set_environment_variables = {
-- 	TERMINFO_DIRS = require 'terminfo',
-- }

config.term = 'wezterm'

-- local color_scheme = is_dark() and 'Github Dark (Gogh)' or 'Catppuccin Latte'
-- local colors = wezterm.get_builtin_color_schemes()[color_scheme]
--
-- config.color_scheme = color_scheme

-- https://wezfurlong.org/wezterm/config/appearance.html#defining-your-own-colors
local colors = {
	background = '#111111',
	foreground = '#c5c8c6',
	cursor = '#20bbfc',
	selection_fg = '#000000',
	selection_bg = '#fffacd',
	inactive_tab_bg = '#1d1f21',
	normal = {
		'#1d1f21',
		'#cc6666',
		'#b5bd68',
		'#f0c674',
		'#81a2be',
		'#b294bb',
		'#8abeb7',
		'#c5c8c6',
	},
	bright = {
		'#333333',
		'#f2777a',
		'#99cc99',
		'#ffcc66',
		'#6699cc',
		'#cc99cc',
		'#66cccc',
		'#dddddd',
	},
}

config.colors = {
	background = colors.background,
	foreground = colors.foreground,
	cursor_bg = colors.cursor,
	cursor_fg = colors.background,
	selection_fg = colors.selection_fg,
	selection_bg = colors.selection_bg,
	ansi = colors.normal,
	brights = colors.bright,
	tab_bar = {
		-- Only works if fancy tab bar is disabled
		background = colors.background,
		-- The color of the inactive tab bar edge/divider
		inactive_tab_edge = colors.background,
		active_tab = {
			bg_color = colors.background,
			fg_color = colors.foreground,
		},
		inactive_tab = {
			bg_color = colors.inactive_tab_bg,
			fg_color = '#808080',
			italic = true,
		},

		inactive_tab_hover = {
			fg_color = colors.background,
			bg_color = colors.foreground,
			italic = true,
		},

		new_tab = {
			bg_color = colors.background,
			fg_color = '#808080',
		},

		new_tab_hover = {
			bg_color = '#3b3052',
			fg_color = '#909090',
			italic = true,
		},
	},
}

-- -- I'm inside Tmux all the time so unlikely that I will lose any important work
config.window_close_confirmation = 'NeverPrompt'
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.window_frame = {
	font = config.font,
	font_size = config.font_size,
	active_titlebar_bg = colors.background,
	inactive_titlebar_bg = colors.background,
}
config.window_decorations = 'RESIZE'
config.window_padding = {
	left = '2cell',
	right = '2cell',
	top = '1cell',
	bottom = '1cell',
}
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = 'CursorColor',
}
config.audible_bell = 'Disabled'
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = 'https://www.github.com/$1/$3',
})

-----------------------------------------------------------------------------
--- Keybindings
----------------------------------------------------------------------------

config.keys = {
	{
		key = 'Enter',
		mods = 'CMD',
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = 'k',
		mods = 'CMD',
		action = wezterm.action_callback(theme_switcher),
	},
	{
		key = 'RightArrow',
		mods = 'CMD',
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = 'LeftArrow',
		mods = 'CMD',
		action = wezterm.action.ActivateTabRelative(-1),
	},
}

-----------------------------------------------------------------------------
--- Events
----------------------------------------------------------------------------

-- wezterm.on('gui-startup', function()
-- 	local tab, pane, window = mux.spawn_window {}
-- 	window:gui_window():maximize()
-- end)

wezterm.on(
	'format-tab-title',
	function(tab, _tabs, _panes, _config, _hover, _max_width)
		local title = #tab.tab_title > 0 and tab.tab_title or tab.active_pane.title

		return {
			{ Text = title },
		}
	end
)

-- https://wezfurlong.org/wezterm/config/lua/gui-events/gui-attached.html?h=maxi
-- Start up the terminal maximized
wezterm.on('gui-attached', function(_domain)
	-- maximize all displayed windows on startup
	local workspace = mux.get_active_workspace()
	for _, window in ipairs(mux.all_windows()) do
		if window:get_workspace() == workspace then
			window:gui_window():maximize()
		end
	end
end)

local function segments_for_right_status(window)
	return {
		window:active_workspace(),
		wezterm.strftime '%a %b %-d %H:%M',
		wezterm.hostname(),
	}
end

wezterm.on('update-status', function(window, _)
	local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
	local segments = segments_for_right_status(window)

	local palette = window:effective_config().resolved_palette
	-- Note the use of wezterm.color.parse here, this returns
	-- a Color object, which comes with functionality for lightening
	-- or darkening the colour (amongst other things).
	local bg = wezterm.color.parse(palette.background)
	local fg = palette.foreground

	-- Each powerline segment is going to be coloured progressively
	-- darker/lighter depending on whether we're on a dark/light colour
	-- scheme. Let's establish the "from" and "to" bounds of our gradient.
	local gradient_to, gradient_from = bg, bg
	if is_dark() then
		gradient_from = gradient_to:lighten(0.2)
	else
		gradient_from = gradient_to:darken(0.2)
	end

	-- Yes, WezTerm supports creating gradients, because why not?! Although
	-- they'd usually be used for setting high fidelity gradients on your terminal's
	-- background, we'll use them here to give us a sample of the powerline segment
	-- colours we need.
	local gradient = wezterm.color.gradient(
		{
			orientation = 'Horizontal',
			colors = { gradient_from, gradient_to },
		},
		#segments -- only gives us as many colours as we have segments.
	)

	-- We'll build up the elements to send to wezterm.format in this table.
	local elements = {}

	for i, seg in ipairs(segments) do
		local is_first = i == 1

		if is_first then
			table.insert(elements, { Background = { Color = 'none' } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })

		table.insert(elements, { Foreground = { Color = fg } })
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = ' ' .. seg .. ' ' })
	end

	window:set_right_status(wezterm.format(elements))
end)

-- local local, ok = pcall(require, 'wezterm-local.lua')
--
-- if ok then
-- config = -- merge configs
-- end

return config
