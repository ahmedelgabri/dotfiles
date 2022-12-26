hs.ipc.cliInstall() -- Ensure the IPC command line client is available
hs.window.animationDuration = 0 -- disable animations
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon 'SpoonInstall'

Install = spoon.SpoonInstall

local layout = require 'layout'
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
	},
}

local ok, url_patterns = pcall(require, 'hosts.' .. hs.host.localizedName())

if ok then
	urlDispatcherConfig.config.url_patterns = url_patterns
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
