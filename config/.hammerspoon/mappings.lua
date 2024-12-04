local utils = require 'utils'

-- https://github.com/mhartington/dotfiles/blob/7dafb67c7be40f373e20c3f443216347c20534ea/hammerspoon/init.lua
local modalKey = { 'alt' }

local focusKeys = {
	-- [g]oogle chrome
	g = utils.appMap.chrome,
	-- [b]rowser (main)
	b = utils.appMap.browser,
	-- [s]lack
	s = utils.appMap.slack,
	-- [t]erminal
	t = utils.appMap.terminal,
	-- i[m]essage
	m = utils.appMap.imessage,
	-- [C]alendar
	c = utils.appMap.calendar,
}

for key in pairs(focusKeys) do
	hs.hotkey.bind(modalKey, key, function()
		hs.application.launchOrFocusByBundleID(focusKeys[key])
	end)
end

hs.hotkey.bind({}, 'f10', hs.openConsole)

--  Mute Zoom (requires enabling global keyboard shortcut in Zoom)
hs.hotkey.bind({}, '§', function()
	hs.eventtap.keyStroke({ 'CMD', 'SHIFT' }, 'a')
end)

hs.hotkey.bind(modalKey, 'r', function()
	hs.reload()
end)
