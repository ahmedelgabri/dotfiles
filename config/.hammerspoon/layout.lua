local log = require 'log'
local utils = require 'utils'

local M = {
	config = {
		externalBrowserPriority = nil,
	},
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

local function resolveTargetScreen(screens)
	return screens.largest or screens.main
end

local function normalizeBrowserPriority(priority)
	if priority == nil then
		return nil
	end

	if type(priority) == 'string' then
		return { priority }
	end

	if type(priority) == 'table' then
		return utils.deepCopy(priority)
	end

	log.wf(
		"Ignoring invalid external browser preference of type '%s'",
		type(priority)
	)
	return nil
end

local function resolveBrowserCandidate(candidate)
	if type(candidate) ~= 'string' or candidate == '' then
		return nil, nil
	end

	local bundleID = utils.getAppBundleID(candidate)
	if bundleID then
		return bundleID, candidate
	end

	if hs.application.infoForBundleID(candidate) then
		return candidate, candidate
	end

	return nil, nil
end

local function resolveExternalBrowser()
	local priority = M.config.externalBrowserPriority or utils.getBrowserPriority()

	for _, candidate in ipairs(priority) do
		local bundleID, resolved = resolveBrowserCandidate(candidate)
		if bundleID then
			return bundleID, resolved
		end
	end

	return nil, nil
end

function M.setExternalBrowserPriority(priority)
	M.config.externalBrowserPriority = normalizeBrowserPriority(priority)
	return M.switchLayout()
end

function M.setExternalBrowser(browser)
	return M.setExternalBrowserPriority(browser)
end

function M.buildLayout(screens)
	local layout = {}
	local browserBundleID = resolveExternalBrowser()

	addLayoutRule(
		layout,
		browserBundleID,
		resolveTargetScreen(screens),
		hs.layout.maximized
	)

	return layout
end

local function layoutSignature(layout, screens)
	local targetScreen = resolveTargetScreen(screens)
	local browserBundleID = resolveExternalBrowser()
	return table.concat({
		tostring(#layout),
		tostring(#screens.all),
		targetScreen and targetScreen:name() or 'unknown',
		tostring(screenArea(targetScreen)),
		tostring(browserBundleID or 'none'),
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

	local targetScreen = resolveTargetScreen(screens)
	if
		targetScreen
		and #screens.all > 1
		and M.state.lastSignature ~= signature
	then
		hs.notify.show(
			'Hammerspoon',
			'Preferred browser moved to largest screen',
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
