local location = require 'location'
local log = require 'log'

local M = {
	started = false,
}

local lastNetwork = nil

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

	if oldNetwork ~= nil then
		notifyNetworkChange(newNetwork)
	end

	if location and location.scheduleUpdate then
		location.scheduleUpdate { reason = 'wifi' }
	end
end

function M.start()
	if M.started then
		return true
	end

	lastNetwork = hs.wifi.currentNetwork()
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
	M.started = false
end

return M
