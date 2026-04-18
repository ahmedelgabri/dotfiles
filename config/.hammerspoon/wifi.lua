local location = require 'location'
local log = require 'log'

local M = {
	started = false,
	state = {
		currentNetwork = nil,
		lastChangedAt = nil,
		previousNetwork = nil,
	},
}

local lastNetwork = nil

local function isoTimestamp()
	return os.date '!%Y-%m-%dT%H:%M:%SZ'
end

local function notifyNetworkChange(newNetwork)
	hs.notify
		.new({
			title = 'Wi-Fi Status',
			subTitle = newNetwork and 'Network:' or 'Disconnected',
			informativeText = newNetwork or 'No network',
			autoWithdraw = true,
			hasActionButton = false,
		})
		:send()
end

local function handleSSIDChange()
	local newNetwork = hs.wifi.currentNetwork()
	if lastNetwork == newNetwork then
		return
	end

	local oldNetwork = lastNetwork
	lastNetwork = newNetwork
	M.state.currentNetwork = newNetwork
	M.state.lastChangedAt = isoTimestamp()
	M.state.previousNetwork = oldNetwork

	if oldNetwork ~= nil then
		notifyNetworkChange(newNetwork)
	end

	if location and location.updateLocationData then
		location.updateLocationData { reason = 'wifi' }
	end
end

function M.getStatus()
	return {
		currentNetwork = M.state.currentNetwork,
		lastChangedAt = M.state.lastChangedAt,
		previousNetwork = M.state.previousNetwork,
		started = M.started,
	}
end

function M.start()
	if M.started then
		return true
	end

	lastNetwork = hs.wifi.currentNetwork()
	M.state.currentNetwork = lastNetwork
	M.state.lastChangedAt = nil
	M.state.previousNetwork = nil
	M.watcher = hs.wifi.watcher.new(handleSSIDChange)
	if not M.watcher then
		log.e 'Failed to create Wi-Fi watcher'
		return false
	end

	M.watcher:start()
	M.started = true
	return true
end

function M.stop()
	if M.watcher then
		M.watcher:stop()
		M.watcher = nil
	end

	lastNetwork = nil
	M.state.currentNetwork = nil
	M.state.lastChangedAt = nil
	M.state.previousNetwork = nil
	M.started = false
end

return M
