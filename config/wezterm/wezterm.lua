local wezterm = require 'wezterm'
local mux = wezterm.mux

local toggle_colorscheme = function(system_appearance)
	if system_appearance:find 'Dark' then
		return 'ayu'
	end
	return 'Catppuccin Latte'
end

local color_scheme = toggle_colorscheme(wezterm.gui.get_appearance())
local colors = wezterm.get_builtin_color_schemes()[color_scheme]

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
local config = wezterm.config_builder and wezterm.config_builder() or {}

config.set_environment_variables = {
	TERMINFO_DIRS = require 'terminfo',
}

config.term = 'wezterm'

config.font = wezterm.font_with_fallback {
	'PragmataPro Liga',
	'Apple Color Emoji',
}
config.color_scheme = color_scheme
config.font_size = 12.0

-- I'm inside Tmux all the time so unlikely that I will lose any important work
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
config.colors = {
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
config.keys = {
	{
		key = 'Enter',
		mods = 'CMD',
		action = wezterm.action.ToggleFullScreen,
	},
}

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = 'https://www.github.com/$1/$3',
})

-- wezterm.on('gui-startup', function()
-- 	local tab, pane, window = mux.spawn_window {}
-- 	window:gui_window():maximize()
-- end)

wezterm.on(
	'format-tab-title',
	function(tab, tabs, panes, config, hover, max_width)
		local title = #tab.tab_title > 0 and tab.tab_title or tab.active_pane.title

		return {
			{ Text = title },
		}
	end
)

-- Start maximize https://github.com/wez/wezterm/discussions/2506#discussioncomment-3619555
wezterm.on('gui-startup', function(window)
	local tab, pane, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	gui_window:perform_action(wezterm.action.ToggleFullScreen, pane)
end)

return config
