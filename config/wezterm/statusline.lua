local battery = require 'battery'
local shared = require 'shared'
local wezterm = require 'wezterm'
local M = {}

function M.left_segments(window)
	local segments = {}

	table.insert(
		segments,
		{ name = 'workspace', value = window:active_workspace() }
	)

	return segments
end

function M.right_segments(window)
	local segments = {}

	local weather_ok, weather_out = wezterm.run_child_process {
		os.getenv 'SHELL',
		'-c',
		'~/.config/tmux/scripts/tmux-weather',
	}

	if weather_ok then
		table.insert(
			segments,
			{ name = 'weather', value = weather_out:gsub('\n', '') }
		)
	end

	table.insert(segments, battery.info()[1])

	local network_ok, network_out = wezterm.run_child_process {
		os.getenv 'SHELL',
		'-c',
		'wifi',
	}

	if network_ok then
		table.insert(segments, { name = 'network', value = network_out })
	end

	local prayer_ok, prayer_out = wezterm.run_child_process {
		os.getenv 'SHELL',
		'-c',
		'~/.config/tmux/scripts/get-prayer',
	}

	if prayer_ok then
		table.insert(segments, { name = 'prayer-time', value = prayer_out })
	end

	local cai_ok, cai_out = wezterm.run_child_process {
		os.getenv 'SHELL',
		'-c',
		'TZ=":/usr/share/zoneinfo/Africa/Cairo" date +%H:%M',
	}

	if cai_ok then
		table.insert(
			segments,
			{ name = 'cairotime', value = 'CAI: ' .. cai_out:gsub('\n', '') }
		)
	end

	table.insert(
		segments,
		{ name = 'datetime', value = wezterm.strftime '%A, %d %b %Y %H:%M' }
	)

	return segments
end

function M.get_right_segments(window)
	local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
	local segments = M.right_segments(window)

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
	if shared.is_dark() then
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

		table.insert(
			elements,
			{ Foreground = { Color = seg.name == 'battery' and seg.color or fg } }
		)
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = ' ' .. seg.value .. ' ' })
	end

	return elements
end

function M.get_left_segments(window)
	local segments = M.left_segments(window)

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
	if shared.is_dark() then
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
		local is_last = i == #segments

		table.insert(
			elements,
			{ Foreground = { Color = seg.name == 'battery' and seg.color or fg } }
		)
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = ' ' .. seg.value .. ' ' })

		if is_last then
			table.insert(elements, { Background = { Color = 'none' } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
	end

	return elements
end

return M
