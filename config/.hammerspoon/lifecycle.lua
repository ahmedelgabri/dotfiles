local layout = require 'layout'
local location = require 'location'
local log = require 'log'
local utils = require 'utils'

local DEFAULT_SETTINGS = {
	enabled = true,
	debounceSeconds = 1,
	layoutDelaySeconds = 0.5,
	locationDelaySeconds = 3,
	watchedEvents = {
		sessionDidBecomeActive = true,
		screensDidUnlock = true,
		screensDidWake = true,
		systemDidWake = true,
	},
}

local EVENT_NAMES = {
	[hs.caffeinate.watcher.sessionDidBecomeActive] = 'sessionDidBecomeActive',
	[hs.caffeinate.watcher.screensDidUnlock] = 'screensDidUnlock',
	[hs.caffeinate.watcher.screensDidWake] = 'screensDidWake',
	[hs.caffeinate.watcher.systemDidWake] = 'systemDidWake',
}

local M = {
	phaseTimers = {},
	settings = utils.deepCopy(DEFAULT_SETTINGS),
	started = false,
	state = {
		lastCompletedAt = nil,
		lastReason = nil,
		lastResult = 'idle',
		lastRunAt = nil,
		lastScheduledAt = nil,
		lastScheduledReason = nil,
		pendingPhases = 0,
		running = false,
	},
	watcher = nil,
}

local function isoTimestamp()
	return os.date '!%Y-%m-%dT%H:%M:%SZ'
end

local function normalizeSettings(settings)
	return utils.deepMerge(DEFAULT_SETTINGS, settings or {})
end

local function cancelPhaseTimers()
	for _, timer in pairs(M.phaseTimers) do
		if timer then
			timer:stop()
		end
	end
	M.phaseTimers = {}
end

local function completePhase(ok)
	if not ok and M.state.lastResult == 'running' then
		M.state.lastResult = 'degraded'
	end

	M.state.pendingPhases = math.max(M.state.pendingPhases - 1, 0)
	if M.state.pendingPhases == 0 then
		M.state.running = false
		if M.state.lastResult == 'running' then
			M.state.lastResult = 'ok'
		end
		M.state.lastCompletedAt = isoTimestamp()
	end
end

local function runPhase(name, fn)
	local ok, result = xpcall(fn, debug.traceback)
	if not ok then
		log.ef("Lifecycle %s phase failed: %s", name, result)
		completePhase(false)
		return
	end

	if result == false then
		log.wf("Lifecycle %s phase reported failure", name)
		completePhase(false)
		return
	end

	completePhase(true)
end

function M.run(reason)
	cancelPhaseTimers()

	local phaseCount = 0
	local runReason = reason or 'manual'

	M.state.lastCompletedAt = nil
	M.state.lastReason = runReason
	M.state.lastResult = 'running'
	M.state.lastRunAt = isoTimestamp()
	M.state.pendingPhases = 0
	M.state.running = true

	local function schedulePhase(id, delaySeconds, fn)
		phaseCount = phaseCount + 1
		M.state.pendingPhases = M.state.pendingPhases + 1
		M.phaseTimers[id] = hs.timer.doAfter(delaySeconds or 0, function()
			M.phaseTimers[id] = nil
			runPhase(id, fn)
		end)
	end

	schedulePhase('layout', M.settings.layoutDelaySeconds, function()
		if layout and layout.switchLayout then
			return layout.switchLayout()
		end
		return false
	end)

	schedulePhase('location', M.settings.locationDelaySeconds, function()
		if location and location.updateLocationData then
			return location.updateLocationData {
				force = true,
				reason = runReason,
			}
		end
		return false
	end)

	if phaseCount == 0 then
		M.state.lastCompletedAt = isoTimestamp()
		M.state.lastResult = 'noop'
		M.state.running = false
	end

	return true
end

function M.schedule(reason)
	if M.settings.enabled == false then
		return false
	end

	M.state.lastScheduledAt = isoTimestamp()
	M.state.lastScheduledReason = reason or 'manual'
	utils.debounce('lifecycle.run', M.settings.debounceSeconds or 0, function()
		M.run(reason)
	end)
	return true
end

local function shouldHandleEvent(name)
	local watchedEvents = M.settings.watchedEvents or {}
	return watchedEvents[name] ~= false
end

local function handleEvent(event)
	local name = EVENT_NAMES[event] or tostring(event)
	if not shouldHandleEvent(name) then
		return
	end

	log.df('Lifecycle event: %s', name)
	M.schedule(name)
end

local function stopWatcher()
	if M.watcher then
		M.watcher:stop()
		M.watcher = nil
	end
end

local function startWatcher()
	stopWatcher()
	if M.settings.enabled == false then
		return true
	end

	M.watcher = hs.caffeinate.watcher.new(handleEvent)
	if not M.watcher then
		log.e 'Failed to create lifecycle watcher'
		return false
	end

	M.watcher:start()
	return true
end

function M.getConfig()
	return utils.deepCopy(M.settings)
end

function M.getStatus()
	return {
		enabled = M.settings.enabled ~= false,
		lastCompletedAt = M.state.lastCompletedAt,
		lastReason = M.state.lastReason,
		lastResult = M.state.lastResult,
		lastRunAt = M.state.lastRunAt,
		lastScheduledAt = M.state.lastScheduledAt,
		lastScheduledReason = M.state.lastScheduledReason,
		pendingPhases = M.state.pendingPhases,
		running = M.state.running,
		started = M.started,
		watching = M.watcher ~= nil,
	}
end

function M.configure(overrides)
	M.settings = utils.deepMerge(M.settings, overrides or {})
	if M.started then
		return startWatcher()
	end
	return true
end

function M.setConfig(config)
	M.settings = normalizeSettings(config)
	if M.started then
		return startWatcher()
	end
	return true
end

function M.resetConfig()
	return M.setConfig(DEFAULT_SETTINGS)
end

function M.setup()
	utils.cancelDebounce 'lifecycle.run'
	cancelPhaseTimers()
	M.started = true
	M.state.lastCompletedAt = nil
	M.state.lastReason = nil
	M.state.lastResult = 'idle'
	M.state.lastRunAt = nil
	M.state.lastScheduledAt = nil
	M.state.lastScheduledReason = nil
	M.state.pendingPhases = 0
	M.state.running = false
	return startWatcher()
end

function M.stop()
	utils.cancelDebounce 'lifecycle.run'
	cancelPhaseTimers()
	stopWatcher()
	M.started = false
	M.state.pendingPhases = 0
	M.state.running = false
end

return M
