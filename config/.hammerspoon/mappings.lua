local M = {}
local log = require 'log'
local utils = require 'utils'

M.hyperKey = { 'shift', 'ctrl', 'alt', 'cmd' }

M.layers = {
	-- [b]rowse
	b = {
		-- [m]ail
		m = function()
			hs.urlevent.openURL 'https://fastmail.com'
		end,
		-- [r]eddit
		r = function()
			hs.urlevent.openURL 'https://reddit.com'
		end,
		-- [h]ackernews
		h = function()
			hs.urlevent.openURL 'raycast://extensions/thomas/hacker-news/frontpage'
		end,
		-- [f]acebook
		f = function()
			hs.urlevent.openURL 'https://facebook.com'
		end,
		-- [y]outube
		y = function()
			hs.urlevent.openURL 'https://youtube.com'
		end,
		x = function()
			hs.urlevent.openURL 'https://x.com'
		end,
		-- [c]ode
		c = function()
			hs.urlevent.openURL 'https://github.com'
		end,
	},
	-- [o]pen
	o = {
		-- [1]Password
		['1'] = function()
			hs.application.launchOrFocusByBundleID(utils.appMap['1password'])
		end,
		-- [g]oogle chrome
		g = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.chrome)
		end,
		-- [f]irefox
		b = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.firefox)
		end,
		-- s[l]ack
		s = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.slack)
		end,
		-- i[m]essage
		m = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.imessage)
		end,
		-- [t]erminal
		t = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.ghostty)
		end,
		-- [C]alendar
		c = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.calendar)
		end,
		-- [z]oom
		z = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.zoom)
		end,
		-- [d]iscord
		d = function()
			hs.application.launchOrFocusByBundleID(utils.appMap.discord)
		end,
	},
}

function M.setup()
	log.info()
	for layer in pairs(M.layers) do
		local m = hs.hotkey.modal.new(M.hyperKey, layer)
		local subLayer = M.layers[layer]

		function m:entered()
			local msg = m.k.msg .. ' mode on'

			log.i(msg)
		end

		function m:exited()
			local msg = m.k.msg .. ' mode off'

			log.i(msg)
		end

		m:bind('', 'escape', function()
			m:exit()
		end)

		for subLayerKey in pairs(subLayer) do
			m:bind('', subLayerKey, function()
				log.i(m.k.msg .. ' + ' .. subLayerKey .. ' pressed')
				subLayer[subLayerKey]()
				m:exit()
			end)
		end
	end

	-- local resizeMappings = {
	-- 	h = { x = 0, y = 0, w = 0.5, h = 1 },
	-- 	j = { x = 0, y = 0.5, w = 1, h = 0.5 },
	-- 	k = { x = 0, y = 0, w = 1, h = 0.5 },
	-- 	l = { x = 0.5, y = 0, w = 0.5, h = 1 },
	-- 	m = { x = 0, y = 0, w = 1, h = 1 },
	-- 	u = { x = 0, y = 0, w = 0.33, h = 1 },
	-- 	i = { x = 0.33, y = 0, w = 0.33, h = 1 },
	-- 	o = { x = 0.66, y = 0, w = 0.33, h = 1 },
	-- }
	--
	-- for key in pairs(resizeMappings) do
	-- 	hs.hotkey.bind(modalKey, key, function()
	-- 		local win = hs.window.focusedWindow()
	-- 		if win then
	-- 			win:moveToUnit(resizeMappings[key])
	-- 		end
	-- 	end)
	-- end

	hs.hotkey.bind({}, 'f10', hs.openConsole)

	--  Mute Zoom (requires enabling global keyboard shortcut in Zoom)/Google Meet
	hs.hotkey.bind({}, '§', function()
		if hs.application.find(utils.appMap.zoom) then
			hs.application.get(utils.appMap.zoom):activate()
			hs.eventtap.keyStroke({ 'CMD', 'SHIFT' }, 'a')
		elseif hs.application.find(utils.appMap.meet) then
			hs.application.get(utils.appMap.meet):activate()
			hs.eventtap.keyStroke({ 'CMD' }, 'd')
		end
	end)

	hs.hotkey.bind({ 'alt', 'cmd' }, 'r', function()
		hs.reload()
	end)
end

return M
