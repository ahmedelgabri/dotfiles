local log = require 'log'

local M = {
	appMap = {},
	debouncers = {},
	fileWatchers = {},
	settings = {},
}

function M.deepCopy(value)
	if type(value) ~= 'table' then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[M.deepCopy(key)] = M.deepCopy(item)
	end
	return copy
end

function M.isList(tbl)
	if type(tbl) ~= 'table' then
		return false
	end

	local maxIndex = 0
	local count = 0

	for key in pairs(tbl) do
		if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then
			return false
		end
		count = count + 1
		if key > maxIndex then
			maxIndex = key
		end
	end

	return maxIndex == count
end

function M.mergeConfig(base, override)
	if type(base) ~= 'table' then
		return M.deepCopy(override)
	end

	local merged = M.deepCopy(base)
	if type(override) ~= 'table' then
		return merged
	end

	for key, value in pairs(override) do
		if type(value) == 'table' and type(merged[key]) == 'table' then
			if M.isList(value) or M.isList(merged[key]) then
				merged[key] = M.deepCopy(value)
			else
				merged[key] = M.mergeConfig(merged[key], value)
			end
		else
			merged[key] = M.deepCopy(value)
		end
	end

	return merged
end

M.deepMerge = M.mergeConfig

function M.expandPath(path)
	if type(path) ~= 'string' or path == '' then
		return path
	end

	if path:sub(1, 2) == '~/' then
		return os.getenv 'HOME' .. path:sub(2)
	end

	if path == '~' then
		return os.getenv 'HOME'
	end

	return path
end

function M.pathExists(path)
	local expanded = M.expandPath(path)
	return expanded ~= nil and hs.fs.attributes(expanded) ~= nil
end

function M.firstExistingPath(paths)
	for _, path in ipairs(paths or {}) do
		local expanded = M.expandPath(path)
		if M.pathExists(expanded) then
			return expanded
		end
	end
end

function M.bundleIDForPath(path)
	local expanded = M.expandPath(path)
	if not expanded then
		return nil
	end

	local info = hs.application.infoForBundlePath(expanded)
	if info then
		return info.CFBundleIdentifier
	end
end

function M.resolveApp(spec)
	if type(spec) == 'string' then
		return spec
	end

	if type(spec) ~= 'table' then
		return nil
	end

	local path = M.firstExistingPath(spec.paths or {})
	if path then
		local bundleID = M.bundleIDForPath(path)
		if bundleID then
			return bundleID
		end
	end

	for _, bundleID in ipairs(spec.bundleIDs or {}) do
		if hs.application.infoForBundleID(bundleID) then
			return bundleID
		end
	end

	return nil
end

function M.resolveApps(appConfig)
	local resolved = {}
	for key, spec in pairs(appConfig or {}) do
		resolved[key] = M.resolveApp(spec)
	end
	return resolved
end

function M.setup(settings)
	M.settings = settings or {}
	M.appMap = M.resolveApps(M.settings.apps or {})
	return M.appMap
end

function M.getAppBundleID(appKey)
	return M.appMap[appKey]
end

function M.launchOrFocus(appKey, opts)
	opts = opts or {}
	local bundleID = M.getAppBundleID(appKey)

	if not bundleID then
		log.wf(
			"App '%s' is not installed or could not be resolved",
			tostring(appKey)
		)
		if opts.notify ~= false then
			hs.notify.show('Hammerspoon', 'App not found', tostring(appKey))
		end
		return false
	end

	local ok = hs.application.launchOrFocusByBundleID(bundleID)
	if not ok then
		log.wf("Unable to launch or focus '%s' (%s)", tostring(appKey), bundleID)
		if opts.notify ~= false then
			hs.notify.show('Hammerspoon', 'Unable to open app', tostring(appKey))
		end
		return false
	end

	return true
end

function M.openURL(url, appKey)
	if appKey then
		local bundleID = M.getAppBundleID(appKey)
		if bundleID then
			hs.application.launchOrFocusByBundleID(bundleID)
			hs.urlevent.openURLWithBundle(url, bundleID)
			return true
		end

		log.wf(
			"No bundle ID available for '%s'; opening URL with system handler",
			tostring(appKey)
		)
	end

	hs.urlevent.openURL(url)
	return true
end

function M.debounce(id, seconds, fn)
	if M.debouncers[id] then
		M.debouncers[id]:stop()
	end

	M.debouncers[id] = hs.timer.delayed.new(seconds, function()
		M.debouncers[id] = nil
		fn()
	end)
	M.debouncers[id]:start()
end

function M.cancelDebounce(id)
	if M.debouncers[id] then
		M.debouncers[id]:stop()
		M.debouncers[id] = nil
	end
end

local function shouldReload(files)
	for _, file in ipairs(files or {}) do
		if file:match '%.lua$' or file:match '%.json$' or file:match '%.jsonc$' then
			return true
		end
	end
	return false
end

function M.stopConfigWatcher()
	for _, watcher in ipairs(M.fileWatchers) do
		watcher:stop()
	end
	M.fileWatchers = {}
	M.cancelDebounce 'config.reload'
end

function M.startConfigWatcher(paths, debounceSeconds)
	M.stopConfigWatcher()

	local watchPaths = paths or { hs.configdir }
	if type(watchPaths) == 'string' then
		watchPaths = { watchPaths }
	end

	local started = false
	for _, path in ipairs(watchPaths) do
		local expanded = M.expandPath(path)
		if expanded and M.pathExists(expanded) then
			local watcher = hs.pathwatcher.new(expanded, function(files)
				if not shouldReload(files) then
					return
				end

				M.debounce('config.reload', debounceSeconds or 0.5, hs.reload)
			end)
			watcher:start()
			table.insert(M.fileWatchers, watcher)
			started = true
		else
			log.wf(
				"Skipping missing config watch path '%s'",
				tostring(expanded or path)
			)
		end
	end

	if not started then
		log.w 'No config watchers started'
	end
end

function M.reloadConfig(paths, debounceSeconds)
	M.startConfigWatcher(paths, debounceSeconds)
end

return M
