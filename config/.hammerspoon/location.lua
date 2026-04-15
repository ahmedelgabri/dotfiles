local log = require 'log'
local utils = require 'utils'

local M = {
	lastUpdateAt = 0,
	settings = {},
	warnedServicesDisabled = false,
}

local function isoTimestamp()
	return os.date '!%Y-%m-%dT%H:%M:%SZ'
end

local function locationServicesEnabled()
	local enabled = hs.location.servicesEnabled()
	if enabled then
		M.warnedServicesDisabled = false
		return true
	end

	if not M.warnedServicesDisabled then
		log.w 'Location services are disabled'
		M.warnedServicesDisabled = true
	end

	return false
end

function M.writeLocationData(data)
	local payload = utils.deepCopy(data or {})
	if type(payload.location) == 'table' then
		payload.location.__luaSkinType = nil
	end
	payload.updatedAt = payload.updatedAt or isoTimestamp()

	local path = M.settings.outputPath
		or (hs.fs.temporaryDirectory() .. '.location.json')
	local ok, err = pcall(hs.json.write, payload, path, true, true)

	if ok then
		log.i('Location written to ' .. path)
	else
		log.ef('Failed to write location to %s: %s', path, tostring(err))
	end

	return ok
end

function M.sanitizeLocationResult(item)
	local payload = utils.deepCopy(item or {})
	if type(payload.location) == 'table' then
		payload.location.__luaSkinType = nil
	end
	payload.updatedAt = isoTimestamp()
	return payload
end

function M.fallbackLocationData(loc, reason)
	local payload = {
		location = utils.deepCopy(loc or {}),
		locality = '',
		error = reason,
		updatedAt = isoTimestamp(),
	}

	if type(payload.location) == 'table' then
		payload.location.__luaSkinType = nil
	end

	return payload
end

function M.reverseGeocode(loc, callback)
	hs.location.geocoder.lookupLocation(loc, function(state, result)
		if not state or type(result) ~= 'table' or type(result[1]) ~= 'table' then
			callback(nil, 'reverse geocode failed')
			return
		end

		callback(M.sanitizeLocationResult(result[1]))
	end)
end

function M.updateLocationData(opts)
	opts = opts or {}
	if not locationServicesEnabled() then
		return false
	end

	local now = hs.timer.secondsSinceEpoch()
	local debounceSeconds = M.settings.debounceSeconds or 0
	if
		not opts.force
		and M.lastUpdateAt > 0
		and now - M.lastUpdateAt < debounceSeconds
	then
		return false
	end

	local loc = hs.location.get()
	if not loc then
		log.w 'No location found'
		return false
	end

	M.lastUpdateAt = now
	M.reverseGeocode(loc, function(result, reason)
		if result then
			M.writeLocationData(result)
		else
			M.writeLocationData(
				M.fallbackLocationData(loc, reason or 'reverse geocode failed')
			)
		end
	end)

	return true
end

function M.scheduleUpdate(opts)
	utils.debounce('location.update', M.settings.debounceSeconds or 0, function()
		M.updateLocationData(opts)
	end)
end

function M.setup(settings)
	M.settings = settings.location or {}
	M.lastUpdateAt = 0

	if not locationServicesEnabled() then
		return false
	end

	hs.timer.doAfter(M.settings.initialLookupDelaySeconds or 1, function()
		M.updateLocationData { force = true, reason = 'startup' }
	end)

	return true
end

function M.stop()
	utils.cancelDebounce 'location.update'
end

return M
