local log = require 'log'
local utils = require 'utils'

local DEFAULT_SETTINGS = {
	hyper = { 'shift', 'ctrl', 'alt', 'cmd' },
	reload = {
		mods = { 'alt', 'cmd' },
		key = 'r',
	},
	console = {
		mods = {},
		key = 'f10',
	},
	meetingMute = {
		mods = {},
		key = '§',
		activationDelaySeconds = 0.2,
		restorePreviousApp = false,
		bindings = {
			zoom = { mods = { 'cmd', 'shift' }, key = 'a' },
			meet = { mods = { 'cmd' }, key = 'd' },
		},
	},
}

local OVERLAY_STYLE = {
	backgroundColor = { white = 0.08, alpha = 0.82 },
	font = 'PragmataPro Mono',
	fontSize = 14,
	lineHeight = 18,
	margin = 0,
	maxWidthFraction = 0.35,
	minWidth = 80,
	padding = 12,
	textColor = { white = 1, alpha = 0.95 },
}

local M = {
	overlayCanvas = nil,
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
	settings = utils.deepCopy(DEFAULT_SETTINGS),
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
	if M.overlayCanvas then
		M.overlayCanvas:delete()
		M.overlayCanvas = nil
	end
end

local function overlayTargetScreen()
	local focusedWindow = hs.window.frontmostWindow()
	if focusedWindow then
		local screen = focusedWindow:screen()
		if screen then
			return screen
		end
	end

	return hs.screen.mainScreen() or hs.screen.primaryScreen()
end

local function overlayRow(key, label, keyWidth)
	return string.format('%-' .. keyWidth .. 's  %s', key, label)
end

local function overlayLines(triggerKey, layer)
	local actionKeys = {}
	for actionKey in pairs(layer.actions) do
		table.insert(actionKeys, actionKey)
	end
	table.sort(actionKeys)

	local maxVisibleActions = #actionKeys
	local visibleActionCount = math.min(#actionKeys, maxVisibleActions)
	local keyWidth = #'esc'

	for index = 1, visibleActionCount do
		keyWidth = math.max(keyWidth, #tostring(actionKeys[index]))
	end

	local lines = {
		string.format('[%s] %s', triggerKey, layer.label),
		'',
	}

	for index = 1, visibleActionCount do
		local actionKey = actionKeys[index]
		local action = layer.actions[actionKey]
		table.insert(lines, overlayRow(actionKey, action.label, keyWidth))
	end

	if #actionKeys > visibleActionCount then
		table.insert(
			lines,
			overlayRow(
				'...',
				string.format('and %d more', #actionKeys - visibleActionCount),
				keyWidth
			)
		)
	end

	table.insert(lines, '')
	table.insert(lines, overlayRow('esc', 'cancel', keyWidth))

	return lines
end

local function overlayFrame(lines, screenFrame)
	local longestLine = 0
	for _, line in ipairs(lines) do
		longestLine = math.max(longestLine, #line)
	end

	local estimatedWidth = math.floor(
		longestLine * (OVERLAY_STYLE.fontSize * 0.62) + OVERLAY_STYLE.padding * 2
	)
	local maxWidth = math.floor(screenFrame.w * OVERLAY_STYLE.maxWidthFraction)
	local width =
		math.min(math.max(estimatedWidth, OVERLAY_STYLE.minWidth), maxWidth)
	local height = OVERLAY_STYLE.padding * 2 + (#lines * OVERLAY_STYLE.lineHeight)

	return {
		x = screenFrame.x + screenFrame.w - width - OVERLAY_STYLE.margin,
		y = screenFrame.y + screenFrame.h - height - OVERLAY_STYLE.margin,
		w = width,
		h = height,
	}
end

local function showLayerOverlay(triggerKey, layer)
	hideLayerOverlay()

	local lines = overlayLines(triggerKey, layer)
	local screen = overlayTargetScreen()
	if not screen then
		return
	end

	local frame = overlayFrame(lines, screen:frame())
	local textFrame = {
		x = OVERLAY_STYLE.padding,
		y = OVERLAY_STYLE.padding,
		w = frame.w - OVERLAY_STYLE.padding * 2,
		h = frame.h - OVERLAY_STYLE.padding * 2,
	}

	local canvas = hs.canvas.new(frame)
	canvas:level 'floating'
	canvas:behaviorAsLabels { 'moveToActiveSpace', 'transient' }
	canvas[1] = {
		type = 'rectangle',
		action = 'fill',
		fillColor = OVERLAY_STYLE.backgroundColor,
		frame = { x = 0, y = 0, w = '100%', h = '100%' },
		roundedRectRadii = { xRadius = 0, yRadius = 0 },
	}
	canvas[2] = {
		type = 'text',
		text = table.concat(lines, '\n'),
		frame = textFrame,
		textColor = OVERLAY_STYLE.textColor,
		textFont = OVERLAY_STYLE.font,
		textSize = OVERLAY_STYLE.fontSize,
		textAlignment = 'left',
		textLineBreak = 'wordWrap',
		withShadow = false,
	}
	canvas:show()

	M.overlayCanvas = canvas
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

local function bindLayer(triggerKey, layer)
	local modal = hs.hotkey.modal.new(M.settings.hyper, triggerKey)
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

local function meetingBindings()
	return M.settings.meetingMute.bindings or {}
end

local function findMeetingApp()
	local frontmostApp = hs.application.frontmostApplication()
	if frontmostApp then
		for appKey in pairs(meetingBindings()) do
			if frontmostApp:bundleID() == utils.getAppBundleID(appKey) then
				return appKey, frontmostApp
			end
		end
	end

	for appKey in pairs(meetingBindings()) do
		local bundleID = utils.getAppBundleID(appKey)
		if bundleID then
			local app = hs.application.get(bundleID)
			if app then
				return appKey, app
			end
		end
	end
end

local function activateAndSendKeystroke(appKey, app)
	local binding = meetingBindings()[appKey]
	if not binding or not app then
		return false
	end

	local previousApp = hs.application.frontmostApplication()
	app:activate()

	hs.timer.doAfter(
		M.settings.meetingMute.activationDelaySeconds or 0.2,
		function()
			hs.eventtap.keyStroke(binding.mods, binding.key)
			if
				M.settings.meetingMute.restorePreviousApp
				and previousApp
				and previousApp:bundleID() ~= app:bundleID()
			then
				previousApp:activate()
			end
		end
	)

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

	return activateAndSendKeystroke(appKey, app)
end

local function bindHotkey(spec, fn)
	if spec and spec.key then
		hs.hotkey.bind(spec.mods or {}, spec.key, fn)
	end
end

function M.setup()
	M.settings = utils.deepCopy(DEFAULT_SETTINGS)

	for triggerKey, layer in pairs(M.layers) do
		bindLayer(triggerKey, layer)
	end

	bindHotkey(M.settings.console, hs.openConsole)
	bindHotkey(M.settings.reload, hs.reload)
	bindHotkey(
		M.settings.meetingMute,
		safeAction('meeting mute', toggleMeetingMute)
	)
end

return M
