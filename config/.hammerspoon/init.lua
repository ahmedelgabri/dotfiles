-- ╔═════════════════════════════════════════════╗
-- ║Add a new path to Lua's package.path         ║
-- ╚═════════════════════════════════════════════╝
local new_path = os.getenv 'HOME'
	.. '/.local/share/'
	.. hs.host.localizedName()
	.. '/hammerspoon/?.lua'
package.path = package.path .. ';' .. new_path

-- ╔══════╗
-- ║CONFIG║
-- ╚══════╝
hs.ipc.cliInstall() -- Ensure the IPC command line client is available
hs.ipc.cliSaveHistory(true) -- save CLI history

hs.window.animationDuration = 0 -- disable animations
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon 'SpoonInstall'

Install = spoon.SpoonInstall
Install:updateAllRepos()

Install:andUse 'EmmyLua'

-- ╔══════════════════╗
-- ║setting up modules║
-- ╚══════════════════╝
local layout = require 'layout'
local log = require 'log'
local mappings = require 'mappings'
local utils = require 'utils'
local window = require 'window-management'

mappings.setup()
window.setup()
-- layout.layoutWatcher:start()

-- ╔════════╗
-- ║Caffeine║
-- ╚════════╝
Install:andUse('Caffeine', {
	start = true,
})

-- ╔═════════════╗
-- ║URLDispatcher║
-- ╚═════════════╝
local urlDispatcherConfig = {
	start = true,
	config = {
		default_handler = utils.appMap.firefox,
		decode_slack_redir_urls = true,
		set_system_handler = true,
		url_patterns = {
			-- App links
			{ 'https?://%w+.zoom.us/j/', 'us.zoom.xos' },
		},
	},
}

Install:andUse('URLDispatcher', urlDispatcherConfig)
spoon.URLDispatcher.logger.setLogLevel 'debug'

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║Custom location logic, I use the generated file in other scripts ║
-- ╚═════════════════════════════════════════════════════════════════╝
function writeLocationData(data)
	local path = hs.fs.temporaryDirectory() .. '.location.json'

	local ok, _ = pcall(hs.json.write, data, path, true, true)

	if ok then
		log.i('Location written to ' .. path)
	else
		log.e('Failed to write location to ' .. path)
	end
end

function updateLocationData()
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

			writeLocationData(result[1])
		else
			writeLocationData { location = loc, locality = '' }
		end
	end)
end

if hs.location.servicesEnabled() then
	hs.location.start()
	hs.timer.doAfter(1, function()
		updateLocationData()
	end)
	hs.location.stop()
else
	log.e 'Location services disabled!n'
end

-- Update location data if we change wifi (can mean we moved to a new location)
-- since there is no watcher for location available
wifiWatcher = hs.wifi.watcher
	.new(function()
		updateLocationData()
	end)
	:start()

-- ╔════════════════════════════╗
-- ║Auto reload config on change║
-- ╚════════════════════════════╝
function ReloadConfig(files)
	local doReload = false
	for _, file in pairs(files) do
		if file:sub(-4) == '.lua' then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

MyWatcher =
	hs.pathwatcher.new(os.getenv 'HOME' .. '/.hammerspoon/', ReloadConfig):start()

hs.alert 'Config loaded'

pcall(require, hs.host.localizedName())
