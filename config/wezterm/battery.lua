local wezterm = require 'wezterm'
local M = {}

function M.info()
	local info = {}
	local icons = { ' ', ' ', ' ', ' ' }
	local color = ''

	for _, battery in ipairs(wezterm.battery_info()) do
		local icon = icons[math.ceil(battery.charge / 25)]

		if battery.state_of_charge < 0.25 then
			color = 'red'
		end

		table.insert(info, {
			name = 'battery',
			color = color,
			value = string.format(
				'%d%% %s',
				math.floor(battery.state_of_charge * 100),
				icon
			),
		})
	end

	return info
end

return M
