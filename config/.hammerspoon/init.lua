local start = hs.timer.absoluteTime()
local log = require 'log'
local utils = require 'utils'

hs.ipc.cliInstall()
hs.ipc.cliSaveHistory(true)
hs.window.animationDuration = 0
hs.application.enableSpotlightForNameSearches(true)

local extraPath = os.getenv 'HOME'
	.. '/.local/share/'
	.. hs.host.localizedName()
	.. '/hammerspoon/?.lua'

if not package.path:find(extraPath, 1, true) then
	package.path = package.path .. ';' .. extraPath
end

log.i 'Resolving app map'
utils.setup()

log.i 'Loading modules'
local layout = require 'layout'
local location = require 'location'
local mappings = require 'mappings'
local spoons = require 'spoons'
local wifi = require 'wifi'
local window = require 'window-management'

log.i 'Setting up spoons'
spoons.setup()

log.i 'Setting up mappings'
mappings.setup()

log.i 'Setting up window management'
window.setup()

log.i 'Setting up location'
location.setup()

log.i 'Starting Wi-Fi watcher'
wifi.start()

log.i 'Setting up layout watcher'
layout.setup()

log.i 'Starting config watcher'
utils.startConfigWatcher()

log.i 'Loading host override'
local ok, hostErr = pcall(require, hs.host.localizedName())
if not ok then
	log.wf('Host override failed to load: %s', tostring(hostErr))
end

local elapsed = math.floor((hs.timer.absoluteTime() - start) / 1000000)
hs.alert 'Config loaded'
hs.notify.show('Hammerspoon', '', string.format('Initialized in %dms', elapsed))
log.i(string.format('Configuration initialized (%dms)', elapsed))
