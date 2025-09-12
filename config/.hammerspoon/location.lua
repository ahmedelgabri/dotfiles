local log = require 'log'

local M = {}
-- ╔═════════════════════════════════════════════════════════════════╗
-- ║Custom location logic, I use the generated file in other scripts ║
-- ╚═════════════════════════════════════════════════════════════════╝
function M.writeLocationData(data)
	local path = hs.fs.temporaryDirectory() .. '.location.json'

	local ok, _ = pcall(hs.json.write, data, path, true, true)

	if ok then
		log.i('Location written to ' .. path)
	else
		log.e('Failed to write location to ' .. path)
	end
end

function M.updateLocationData()
	local loc = hs.location.get()

	if not loc then
		log.e 'No location found.'
		return nil
	end

	hs.location.geocoder.lookupLocation(loc, function(state, result)
		if state then
			-- Needed otherwise JSON serialization fails
			-- ERROR:   LuaSkin: Object cannot be serialised as JSON
			-- ERROR:   LuaSkin: Failed to write object to JSON file
			result[1].location['__luaSkinType'] = nil

			M.writeLocationData(result[1])
		else
			M.writeLocationData { location = loc, locality = '' }
		end
	end)
end

function M.setup()
	if hs.location.servicesEnabled() then
		hs.location.start()
		hs.timer.doAfter(1, function()
			M.updateLocationData()
		end)
		hs.location.stop()
	else
		log.e 'Location services disabled!n'
	end
end

return M
