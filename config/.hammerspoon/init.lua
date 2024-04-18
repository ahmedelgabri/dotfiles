hs.ipc.cliInstall() -- Ensure the IPC command line client is available
hs.window.animationDuration = 0 -- disable animations
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon 'SpoonInstall'
hs.loadSpoon 'EmmyLua'

Install = spoon.SpoonInstall

local layout = require 'layout'
local utils = require 'utils'
require 'mappings'
require 'window-managment'

-- layout.layoutWatcher:start()

Install:andUse('Caffeine', {
	start = true,
})

local urlDispatcherConfig = {
	start = true,
	config = {
		default_handler = 'company.thebrowser.Browser',
		decode_slack_redir_urls = true,
		set_system_handler = true,
		url_patterns = {
			-- App links
			{ 'https?://%w+.zoom.us/j/', 'us.zoom.xos' },
			{ 'https?://.*%.slack%.com', 'com.tinyspeck.slackmacgap' },
		},
	},
}

local ok, local_config = pcall(require, 'hosts.' .. hs.host.localizedName())

if ok and local_config ~= nil then
	urlDispatcherConfig = utils.deepMerge(urlDispatcherConfig, local_config)
end

Install:andUse('URLDispatcher', urlDispatcherConfig)

--
-- Auto-reload config on change.
--

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
