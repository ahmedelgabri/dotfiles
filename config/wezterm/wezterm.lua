local shared = require 'shared'
local statusline = require 'statusline'
local wezterm = require 'wezterm'

local mux = wezterm.mux

-- -- In newer versions of wezterm, use the config_builder which will
-- -- help provide clearer error messages
local config = wezterm.config_builder and wezterm.config_builder() or {}

config.term = 'wezterm'

-- replace TMUX? but I have issues with neovim scrolling/redrawing and Wezterm
-- config.unix_domains = {
-- 	{
-- 		name = 'unix',
-- 	},
-- }
--
-- config.default_gui_startup_args = { 'connect', 'unix' }

-----------------------------------------------------------------------------
--- Config
----------------------------------------------------------------------------

config.font = wezterm.font_with_fallback {
	{ family = 'PragmataPro Liga' },
	'Apple Color Emoji',
}
config.font_size = 12.0
-- config.freetype_load_target = 'HorizontalLcd'
-- config.freetype_render_target = 'HorizontalLcd'

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
			bg_color = colors.inactive_tab_bg,
			fg_color = colors.foreground,
		},
		inactive_tab = {
			bg_color = colors.background,
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
config.window_decorations = 'RESIZE|MACOS_FORCE_DISABLE_SHADOW'
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
		action = wezterm.action_callback(shared.theme_switcher),
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

wezterm.on('update-status', function(window, _)
	if os.getenv 'TMUX' ~= nil then
		window:set_left_status(nil)
		window:set_right_status(nil)
		return
	end

	window:set_left_status(wezterm.format(statusline.get_left_segments(window)))
	window:set_right_status(wezterm.format(statusline.get_right_segments(window)))
end)

-- local local, ok = pcall(require, 'wezterm-local.lua')
--
-- if ok then
-- config = -- merge configs
-- end

return config
