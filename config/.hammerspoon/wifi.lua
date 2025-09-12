local M = {}
local location = require 'location'

local function ssidChangedCallback()
	local newNetwork = hs.wifi.currentNetwork()

	-- send notification if we're on a different network than we were before
	if lastNetwork ~= newNetwork then
		hs.notify
			.new({
				title = 'Wi-Fi Status',
				subTitle = newNetwork and 'Network:' or 'Disconnected',
				informativeText = newNetwork,
				autoWithdraw = true,
				hasActionButton = false,
			})
			:send()

		lastNetwork = newNetwork
	end
	-- Update location data if we change wifi (can mean we moved to a new location)
	-- since there is no watcher for location available
	location.updateLocationData()
end

function M.start()
	M.watcher = hs.wifi.watcher.new(ssidChangedCallback)

	M.watcher:start()
end

function M.stop()
	M.watcher:stop()
	M.watcher = nil
end

return M
