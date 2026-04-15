local start = hs.timer.absoluteTime()
local log = require 'log'
local utils = require 'utils'

local function safeCall(label, fn)
	local ok, result = xpcall(fn, debug.traceback)
	if not ok then
		log.ef('%s failed: %s', label, result)
	end
	return ok, result
end

local function safeRequire(name)
	local module
	local ok = safeCall(string.format("require('%s')", name), function()
		module = require(name)
	end)
	if ok then
		return module
	end
end

local function extendPackagePath()
	local extraPath = os.getenv 'HOME'
		.. '/.local/share/'
		.. hs.host.localizedName()
		.. '/hammerspoon/?.lua'

	if not package.path:find(extraPath, 1, true) then
		package.path = package.path .. ';' .. extraPath
	end
end

safeCall('hs.ipc.cliInstall', function()
	hs.ipc.cliInstall()
end)
safeCall('hs.ipc.cliSaveHistory', function()
	hs.ipc.cliSaveHistory(true)
end)

hs.window.animationDuration = 0
hs.application.enableSpotlightForNameSearches(true)

extendPackagePath()
utils.setup()

local layout = safeRequire 'layout'
local location = safeRequire 'location'
local mappings = safeRequire 'mappings'
local spoons = safeRequire 'spoons'
local wifi = safeRequire 'wifi'
local window = safeRequire 'window-management'

if spoons then
	safeCall('spoons.setup', function()
		spoons.setup()
	end)
end

if mappings then
	safeCall('mappings.setup', function()
		mappings.setup()
	end)
end

if window then
	safeCall('window.setup', function()
		window.setup()
	end)
end

if location then
	safeCall('location.setup', function()
		location.setup()
	end)
end

if wifi then
	safeCall('wifi.start', function()
		wifi.start()
	end)
end

if layout then
	safeCall('layout.setup', function()
		layout.setup()
	end)
end

safeCall('utils.startConfigWatcher', function()
	utils.startConfigWatcher()
end)

safeCall('host custom config', function()
	pcall(require, hs.host.localizedName())
end)

local elapsed = math.floor((hs.timer.absoluteTime() - start) / 1000000)
hs.alert 'Config loaded'
hs.notify.show('Hammerspoon', '', string.format('Initialized in %dms', elapsed))
log.i(string.format('Configuration initialized (%dms)', elapsed))
