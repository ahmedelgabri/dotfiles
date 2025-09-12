local start = hs.timer.absoluteTime()

hs.ipc.cliInstall() -- Ensure the IPC command line client is available
hs.ipc.cliSaveHistory(true) -- save CLI history
hs.window.animationDuration = 0 -- disable animations
hs.application.enableSpotlightForNameSearches(true)

local layout = require 'layout'
local location = require 'location'
local log = require 'log'
local mappings = require 'mappings'
local spoons = require 'spoons'
local utils = require 'utils'
local wifi = require 'wifi'
local window = require 'window-management'

-- ╔═════════════════════════════════════════════╗
-- ║Add a new path to Lua's package.path         ║
-- ╚═════════════════════════════════════════════╝
local new_path = os.getenv 'HOME'
	.. '/.local/share/'
	.. hs.host.localizedName()
	.. '/hammerspoon/?.lua'
package.path = package.path .. ';' .. new_path

-- ╔══════════════════╗
-- ║setting up modules║
-- ╚══════════════════╝
spoons.setup()
mappings.setup()
window.setup()
location.setup()
wifi.start()
utils.reloadConfig()

-- layout.layoutWatcher:start()

-- Load host custom/extra config
pcall(require, hs.host.localizedName())

hs.alert 'Config loaded'

local elapsed = math.floor((hs.timer.absoluteTime() - start) / 1000000)
hs.notify.show('Hammerspoon', '', string.format('Initialized in %dms', elapsed))
log.i(string.format('Configuration initialized (%dms)', elapsed))
