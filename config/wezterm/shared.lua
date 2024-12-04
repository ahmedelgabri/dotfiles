local wezterm = require 'wezterm'
local M = {}

function M.is_dark()
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

function M.theme_switcher(window, pane)
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

return M
