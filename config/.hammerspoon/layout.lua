local log = require 'log'
local utils = require 'utils'

local M = {
	state = {
		lastSignature = nil,
	},
}

local function getAllScreens()
	return hs.screen.allScreens()
end

local function screenArea(screen)
	if not screen then
		return 0
	end

	local frame = screen:fullFrame()
	return frame.w * frame.h
end

local function resolveScreens()
	local allScreens = getAllScreens()
	local mainScreen = hs.screen.primaryScreen() or allScreens[1]
	local largestScreen = mainScreen
	local largestArea = screenArea(mainScreen)

	for _, screen in ipairs(allScreens) do
		local area = screenArea(screen)
		if area > largestArea then
			largestScreen = screen
			largestArea = area
		end
	end

	return {
		all = allScreens,
		main = mainScreen,
		largest = largestScreen,
	}
end

local function addLayoutRule(layout, bundleID, screen, unit)
	if bundleID and screen then
		table.insert(layout, { bundleID, nil, screen, unit, nil, nil })
	end
end

function M.buildLayout(screens)
	local layout = {}
	local browserBundleID = utils.resolvePreferredBrowser()

	addLayoutRule(
		layout,
		browserBundleID,
		screens.largest or screens.main,
		hs.layout.maximized
	)

	return layout
end

local function layoutSignature(layout, screens)
	local browserTarget = screens.largest and screens.largest:name()
		or screens.main and screens.main:name()
		or 'unknown'
	return table.concat({
		tostring(#layout),
		tostring(#screens.all),
		browserTarget,
		tostring(screenArea(screens.largest)),
	}, '|')
end

function M.switchLayout()
	local screens = resolveScreens()
	local layout = M.buildLayout(screens)
	if #layout == 0 then
		log.w 'Skipping layout application because no valid rules were generated'
		return false
	end

	local signature = layoutSignature(layout, screens)
	hs.layout.apply(layout)

	local targetScreen = screens.largest or screens.main
	if
		targetScreen
		and #screens.all > 1
		and M.state.lastSignature ~= signature
	then
		hs.notify.show(
			'Hammerspoon',
			'Default browser moved to largest screen',
			targetScreen:name()
		)
	end

	M.state.lastSignature = signature
	return true
end

function M.scheduleLayout()
	utils.debounce('layout.switch', 0.75, function()
		M.switchLayout()
	end)
end

function M.setup()
	M.state.lastSignature = nil
	M.switchLayout()

	if M.layoutWatcher then
		M.layoutWatcher:stop()
	end

	M.layoutWatcher = hs.screen.watcher.newWithActiveScreen(function()
		M.scheduleLayout()
	end)
	M.layoutWatcher:start()
end

function M.stop()
	utils.cancelDebounce 'layout.switch'
	if M.layoutWatcher then
		M.layoutWatcher:stop()
		M.layoutWatcher = nil
	end
end

return M
