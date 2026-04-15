local log = require 'log'
local utils = require 'utils'

local DEFAULT_SETTINGS = {
	outputPath = hs.fs.temporaryDirectory() .. '.location.json',
	debounceSeconds = 5,
}

local M = {
	lastUpdateAt = 0,
	settings = utils.deepCopy(DEFAULT_SETTINGS),
	startupAttempts = 0,
	startupTimer = nil,
	trackingStarted = false,
	warnedServicesDisabled = false,
}

local function isoTimestamp()
	return os.date '!%Y-%m-%dT%H:%M:%SZ'
end

local function sanitizeLocationTable(locationData)
	if type(locationData) == 'table' then
		locationData.__luaSkinType = nil
	end
	return locationData
end

local function cancelStartupTimer()
	if M.startupTimer then
		M.startupTimer:stop()
		M.startupTimer = nil
	end
end

local function stopWarmupTracking()
	if M.trackingStarted then
		hs.location.stop()
		M.trackingStarted = false
	end
end

local function finishStartupWarmup()
	cancelStartupTimer()
	M.startupAttempts = 0
	stopWarmupTracking()
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

local function startWarmupTracking()
	if M.trackingStarted then
		return true
	end

	local ok = hs.location.start()
	if ok then
		M.trackingStarted = true
	else
		log.w 'Failed to start location tracking for startup warmup'
	end

	return ok
end

function M.writeLocationData(data)
	local payload = utils.deepCopy(data or {})
	payload.location = sanitizeLocationTable(payload.location)
	payload.updatedAt = payload.updatedAt or isoTimestamp()

	local path = M.settings.outputPath
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
	payload.location = sanitizeLocationTable(payload.location)
	payload.updatedAt = isoTimestamp()
	return payload
end

function M.fallbackLocationData(loc, reason)
	return {
		location = sanitizeLocationTable(utils.deepCopy(loc or {})),
		locality = '',
		error = reason,
		updatedAt = isoTimestamp(),
	}
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
		if opts.reason == 'startup' then
			log.i(
				string.format(
					'Location not available yet (attempt %d/%d)',
					opts.attempt or 1,
					opts.maxAttempts or 1
				)
			)
		else
			log.w 'No location found'
		end
		return false
	end

	if M.startupAttempts > 0 or M.startupTimer then
		finishStartupWarmup()
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

local function scheduleStartupUpdate(delaySeconds)
	cancelStartupTimer()
	M.startupTimer = hs.timer.doAfter(delaySeconds, function()
		M.startupTimer = nil
		M.startupAttempts = M.startupAttempts + 1

		local attempt = M.startupAttempts
		local maxAttempts = 5
		local ok = M.updateLocationData {
			force = true,
			reason = 'startup',
			attempt = attempt,
			maxAttempts = maxAttempts,
		}

		if ok then
			return
		end

		if attempt < maxAttempts then
			scheduleStartupUpdate(2)
			return
		end

		log.wf('Unable to retrieve location after %d startup attempts', maxAttempts)
		finishStartupWarmup()
	end)
end

function M.scheduleUpdate(opts)
	utils.debounce('location.update', M.settings.debounceSeconds or 0, function()
		M.updateLocationData(opts)
	end)
end

function M.setup()
	M.settings = utils.deepCopy(DEFAULT_SETTINGS)
	M.lastUpdateAt = 0
	M.startupAttempts = 0
	cancelStartupTimer()
	stopWarmupTracking()

	if not locationServicesEnabled() then
		return false
	end

	startWarmupTracking()
	scheduleStartupUpdate(1)

	return true
end

function M.stop()
	utils.cancelDebounce 'location.update'
	finishStartupWarmup()
end

return M
