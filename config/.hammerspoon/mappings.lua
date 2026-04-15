local log = require 'log'
local utils = require 'utils'

local M = {
	overlayID = nil,
	layers = {
		b = {
			label = 'browse',
			actions = {
				m = { label = 'mail', url = 'https://fastmail.com' },
				r = { label = 'reddit', url = 'https://reddit.com' },
				h = {
					label = 'hacker news',
					url = 'raycast://extensions/thomas/hacker-news/frontpage',
				},
				f = { label = 'facebook', url = 'https://facebook.com' },
				y = { label = 'youtube', url = 'https://youtube.com' },
				x = { label = 'x', url = 'https://x.com' },
				c = { label = 'code', url = 'https://github.com' },
			},
		},
		o = {
			label = 'open',
			actions = {
				['1'] = { label = '1Password', app = '1password' },
				g = { label = 'Google Chrome', app = 'chrome' },
				b = { label = 'Firefox', app = 'firefox' },
				s = { label = 'Slack', app = 'slack' },
				m = { label = 'Messages', app = 'imessage' },
				t = { label = 'Terminal', app = 'ghostty' },
				c = { label = 'Calendar', app = 'calendar' },
				z = { label = 'Zoom', app = 'zoom' },
				d = { label = 'Discord', app = 'discord' },
			},
		},
	},
	modals = {},
	settings = {},
}

local meetingBindings = {
	zoom = { mods = { 'cmd', 'shift' }, key = 'a' },
	meet = { mods = { 'cmd' }, key = 'd' },
}

local function safeAction(label, fn)
	return function()
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then
			log.ef("Action '%s' failed: %s", label, err)
		end
	end
end

local function runAction(action)
	if action.fn then
		return action.fn()
	end

	if action.app then
		return utils.launchOrFocus(action.app)
	end

	if action.url then
		return utils.openURL(action.url, action.browser)
	end

	return false
end

local function hideLayerOverlay()
	if M.overlayID then
		hs.alert.closeSpecific(M.overlayID, 0)
		M.overlayID = nil
	end
end

local function showLayerOverlay(triggerKey, layer)
	local layerOverlay = M.settings.hotkeys and M.settings.hotkeys.layerOverlay or {}
	if layerOverlay.enabled == false then
		return
	end

	hideLayerOverlay()

	local actionKeys = {}
	for actionKey in pairs(layer.actions) do
		table.insert(actionKeys, actionKey)
	end
	table.sort(actionKeys)

	local lines = {
		string.format('[%s] %s', triggerKey, layer.label),
		'esc: cancel',
	}

	for _, actionKey in ipairs(actionKeys) do
		local action = layer.actions[actionKey]
		table.insert(lines, string.format('%s: %s', actionKey, action.label))
	end

	M.overlayID = hs.alert.show(table.concat(lines, '\n'), nil, nil, false)
end

local function bindAction(modal, layerKey, actionKey, action)
	modal:bind(
		'',
		actionKey,
		safeAction(action.label, function()
			log.i(string.format('%s + %s pressed', layerKey, actionKey))
			runAction(action)
			modal:exit()
		end)
	)
end

local function bindLayer(triggerKey, layer, hyperKey)
	local modal = hs.hotkey.modal.new(hyperKey, triggerKey)
	M.modals[triggerKey] = modal

	function modal:entered()
		log.i(string.format('%s mode on', layer.label))
		showLayerOverlay(triggerKey, layer)
	end

	function modal:exited()
		log.i(string.format('%s mode off', layer.label))
		hideLayerOverlay()
	end

	modal:bind('', 'escape', function()
		modal:exit()
	end)

	for actionKey, action in pairs(layer.actions) do
		bindAction(modal, triggerKey, actionKey, action)
	end
end

local function findMeetingApp()
	local frontmostApp = hs.application.frontmostApplication()
	if frontmostApp then
		for appKey in pairs(meetingBindings) do
			if frontmostApp:bundleID() == utils.getAppBundleID(appKey) then
				return appKey, frontmostApp
			end
		end
	end

	for appKey in pairs(meetingBindings) do
		local bundleID = utils.getAppBundleID(appKey)
		if bundleID then
			local app = hs.application.get(bundleID)
			if app then
				return appKey, app
			end
		end
	end
end

local function activateAndSendKeystroke(appKey, app, settings)
	local binding = meetingBindings[appKey]
	if not binding or not app then
		return false
	end

	local previousApp = hs.application.frontmostApplication()
	app:activate()

	local meetingHotkey = settings.hotkeys and settings.hotkeys.meetingMute or {}
	hs.timer.doAfter(meetingHotkey.activationDelaySeconds or 0.2, function()
		hs.eventtap.keyStroke(binding.mods, binding.key)
		if
			meetingHotkey.restorePreviousApp
			and previousApp
			and previousApp:bundleID() ~= app:bundleID()
		then
			previousApp:activate()
		end
	end)

	return true
end

local function toggleMeetingMute()
	local appKey, app = findMeetingApp()
	if not appKey or not app then
		log.w 'No supported meeting app is currently running'
		hs.notify.show(
			'Hammerspoon',
			'Meeting mute',
			'No Zoom or Meet app is running'
		)
		return false
	end

	return activateAndSendKeystroke(appKey, app, M.settings)
end

local function bindHotkey(spec, fn)
	if spec and spec.key then
		hs.hotkey.bind(spec.mods or {}, spec.key, fn)
	end
end

function M.setup(settings)
	M.settings = settings or {}
	local hyperKey = M.settings.hotkeys and M.settings.hotkeys.hyper
		or { 'shift', 'ctrl', 'alt', 'cmd' }

	for triggerKey, layer in pairs(M.layers) do
		bindLayer(triggerKey, layer, hyperKey)
	end

	bindHotkey(M.settings.hotkeys and M.settings.hotkeys.console, hs.openConsole)
	bindHotkey(M.settings.hotkeys and M.settings.hotkeys.reload, hs.reload)
	bindHotkey(
		M.settings.hotkeys and M.settings.hotkeys.meetingMute,
		safeAction('meeting mute', toggleMeetingMute)
	)
end

return M
