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

utils.setup()

local layout = require 'layout'
local location = require 'location'
local mappings = require 'mappings'
local spoons = require 'spoons'
local wifi = require 'wifi'
local window = require 'window-management'

spoons.setup()
mappings.setup()
window.setup()
location.setup()
wifi.start()
layout.setup()
utils.startConfigWatcher()

pcall(require, hs.host.localizedName())

local elapsed = math.floor((hs.timer.absoluteTime() - start) / 1000000)
hs.alert 'Config loaded'
hs.notify.show('Hammerspoon', '', string.format('Initialized in %dms', elapsed))
log.i(string.format('Configuration initialized (%dms)', elapsed))
