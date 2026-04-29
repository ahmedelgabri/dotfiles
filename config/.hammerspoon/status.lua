local layout = require 'layout'
local lifecycle = require 'lifecycle'
local location = require 'location'
local log = require 'log'
local prayer = require 'prayer'
local spoons = require 'spoons'
local utils = require 'utils'
local wifi = require 'wifi'

local M = {
	state = {
		lastLoggedAt = nil,
		lastSnapshot = nil,
	},
}

local function isoTimestamp()
	return os.date '!%Y-%m-%dT%H:%M:%SZ'
end

local function safeCall(label, fn)
	local ok, result = xpcall(fn, debug.traceback)
	if not ok then
		log.ef('Status %s failed: %s', label, result)
		return nil
	end
	return result
end

local function locationSummary(locationStatus)
	local payload = locationStatus.lastPayload or {}
	if payload.locality and payload.locality ~= '' then
		return payload.locality
	end

	if locationStatus.servicesEnabled == false then
		return 'disabled'
	end

	if locationStatus.error then
		return 'error: ' .. locationStatus.error
	end

	return 'unknown'
end

local function urlDispatcherSummary(spoonsStatus)
	local urlDispatcher = spoonsStatus.urlDispatcher or {}
	if not urlDispatcher.enabled then
		return 'disabled'
	end

	return table.concat({
		urlDispatcher.defaultHandler or 'none',
		string.format('%d rules', urlDispatcher.ruleCount or 0),
		string.format('%d decoders', urlDispatcher.decoderCount or 0),
	}, ' · ')
end

local function lifecycleSummary(lifecycleStatus)
	if lifecycleStatus.enabled == false then
		return 'disabled'
	end

	if lifecycleStatus.running then
		return string.format(
			'running · %d pending · %s',
			lifecycleStatus.pendingPhases or 0,
			lifecycleStatus.lastReason or 'manual'
		)
	end

	return string.format(
		'%s · %s',
		lifecycleStatus.lastResult or 'idle',
		lifecycleStatus.lastReason or 'n/a'
	)
end

local function prayerSummary(prayerStatus)
	if prayerStatus.error then
		return 'error: ' .. prayerStatus.error
	end

	local nextPrayer = prayerStatus.nextPrayer or {}
	if nextPrayer.label and nextPrayer.time then
		return string.format('%s %s', nextPrayer.label, nextPrayer.time)
	end

	return 'unknown'
end

local function buildSnapshot()
	local layoutStatus = safeCall('layout status', function()
		return layout.getStatus()
	end) or {}
	local lifecycleStatus = safeCall('lifecycle status', function()
		return lifecycle.getStatus()
	end) or {}
	local locationStatus = safeCall('location status', function()
		return location.getStatus()
	end) or {}
	local prayerStatus = safeCall('prayer status', function()
		return prayer.getStatus()
	end) or {}
	local spoonsStatus = safeCall('spoons status', function()
		return spoons.getStatus()
	end) or {}
	local wifiStatus = safeCall('wifi status', function()
		return wifi.getStatus()
	end) or {}

	return {
		host = hs.host.localizedName(),
		layout = layoutStatus,
		lifecycle = lifecycleStatus,
		location = locationStatus,
		log = {
			level = log.getLevel(),
		},
		prayer = prayerStatus,
		spoons = spoonsStatus,
		summary = {
			lifecycle = lifecycleSummary(lifecycleStatus),
			location = locationSummary(locationStatus),
			prayer = prayerSummary(prayerStatus),
			urlDispatcher = urlDispatcherSummary(spoonsStatus),
			wifi = wifiStatus.currentNetwork or 'disconnected',
		},
		wifi = wifiStatus,
	}
end

function M.getStatus()
	return {
		hasSnapshot = M.state.lastSnapshot ~= nil,
		lastLoggedAt = M.state.lastLoggedAt,
	}
end

function M.snapshot()
	local snapshot = buildSnapshot()
	M.state.lastSnapshot = utils.deepCopy(snapshot)
	return snapshot
end

function M.log(snapshot)
	snapshot = utils.deepCopy(snapshot or M.state.lastSnapshot or M.snapshot())
	M.state.lastLoggedAt = isoTimestamp()
	M.state.lastSnapshot = utils.deepCopy(snapshot)
	print(hs.inspect.inspect(snapshot))
	return snapshot
end

function M.clear()
	M.state.lastLoggedAt = nil
	M.state.lastSnapshot = nil
end

return M
