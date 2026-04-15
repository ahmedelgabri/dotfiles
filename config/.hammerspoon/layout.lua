local log = require 'log'
local utils = require 'utils'

local M = {
	settings = {},
	state = {
		lastSignature = nil,
	},
}

local function getAllScreens()
	return hs.screen.allScreens()
end

local function findScreenByNames(names)
	for _, wantedName in ipairs(names or {}) do
		for _, screen in ipairs(getAllScreens()) do
			if screen:name() == wantedName then
				return screen
			end
		end
	end
end

local function resolveScreens(settings)
	local allScreens = getAllScreens()
	local mainScreen = hs.screen.primaryScreen() or allScreens[1]
	local externalScreen = findScreenByNames(settings.layout and settings.layout.preferredExternalNames)

	if not externalScreen then
		for _, screen in ipairs(allScreens) do
			if mainScreen and screen:id() ~= mainScreen:id() then
				externalScreen = screen
				break
			end
		end
	end

	return {
		all = allScreens,
		main = mainScreen,
		external = externalScreen,
	}
end

local function preferredBrowserBundleID(settings)
	local chromeBundleID = utils.getAppBundleID 'chrome'
	if chromeBundleID then
		return chromeBundleID
	end

	for _, appKey in ipairs(settings.urls and settings.urls.defaultBrowserPriority or {}) do
		local bundleID = utils.getAppBundleID(appKey)
		if bundleID then
			return bundleID
		end
	end
end

local function addLayoutRule(layout, bundleID, screen, unit)
	if bundleID and screen then
		table.insert(layout, { bundleID, nil, screen, unit, nil, nil })
	end
end

function M.buildLayout(settings, screens)
	local layout = {}
	local browserScreen = screens.external or screens.main

	addLayoutRule(layout, preferredBrowserBundleID(settings), browserScreen, hs.layout.maximized)
	addLayoutRule(layout, utils.getAppBundleID('x'), screens.main, hs.layout.right30)
	addLayoutRule(layout, utils.getAppBundleID('slack'), screens.main, hs.layout.maximized)

	return layout
end

local function layoutSignature(layout, screens)
	local browserTarget = screens.external and screens.external:name()
		or screens.main and screens.main:name()
		or 'unknown'
	return table.concat({ tostring(#layout), tostring(#screens.all), browserTarget }, '|')
end

function M.switchLayout()
	local screens = resolveScreens(M.settings)
	local layout = M.buildLayout(M.settings, screens)
	if #layout == 0 then
		log.w 'Skipping layout application because no valid rules were generated'
		return false
	end

	local signature = layoutSignature(layout, screens)
	hs.layout.apply(layout)

	local targetScreen = screens.external or screens.main
	if
		targetScreen
		and M.settings.layout
		and M.settings.layout.notifyOnApply
		and #screens.all > 1
		and M.state.lastSignature ~= signature
	then
		hs.notify.show(
			'Hammerspoon',
			string.format('%d monitor layout activated', #screens.all),
			targetScreen:name()
		)
	end

	M.state.lastSignature = signature
	return true
end

function M.scheduleLayout()
	utils.debounce('layout.switch', M.settings.layout and M.settings.layout.debounceSeconds or 0.75, function()
		M.switchLayout()
	end)
end

function M.setup(settings)
	M.settings = settings or {}
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
