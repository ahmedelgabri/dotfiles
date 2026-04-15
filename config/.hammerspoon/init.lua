local start = hs.timer.absoluteTime()
local log = require 'log'
local utils = require 'utils'
local defaultSettings = require 'config'

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

local function loadHostOverrides()
	local hostPath = hs.configdir .. '/hosts/' .. hs.host.localizedName() .. '.lua'
	if not utils.pathExists(hostPath) then
		log.i('No host overrides found for ' .. hs.host.localizedName())
		return {}
	end

	local chunk, loadErr = loadfile(hostPath)
	if not chunk then
		log.ef('Failed to load host overrides from %s: %s', hostPath, loadErr)
		return {}
	end

	local overrides
	local ok = safeCall('host overrides', function()
		overrides = chunk()
	end)
	if not ok then
		return {}
	end

	if type(overrides) ~= 'table' then
		log.wf('Ignoring host overrides from %s because it did not return a table', hostPath)
		return {}
	end

	log.i('Loaded host overrides from ' .. hostPath)
	return overrides
end

local settings = utils.mergeConfig(defaultSettings, loadHostOverrides())
log.applySettings(settings)

extendPackagePath()

safeCall('hs.ipc.cliInstall', function()
	hs.ipc.cliInstall()
end)
safeCall('hs.ipc.cliSaveHistory', function()
	hs.ipc.cliSaveHistory(true)
end)

hs.window.animationDuration = 0
hs.application.enableSpotlightForNameSearches(true)

utils.setup(settings)

local layout = safeRequire 'layout'
local location = safeRequire 'location'
local mappings = safeRequire 'mappings'
local spoons = safeRequire 'spoons'
local wifi = safeRequire 'wifi'
local window = safeRequire 'window-management'

if settings.features.spoons and spoons then
	safeCall('spoons.setup', function()
		spoons.setup(settings)
	end)
end

if mappings then
	safeCall('mappings.setup', function()
		mappings.setup(settings)
	end)
end

if window then
	safeCall('window.setup', function()
		window.setup(settings)
	end)
end

if settings.features.location and location then
	safeCall('location.setup', function()
		location.setup(settings)
	end)
end

if settings.features.wifiWatcher and wifi then
	safeCall('wifi.start', function()
		wifi.start(settings)
	end)
end

if settings.features.layout and layout then
	safeCall('layout.setup', function()
		layout.setup(settings)
	end)
end

if settings.features.autoReload then
	safeCall('utils.startConfigWatcher', function()
		utils.startConfigWatcher(
			settings.reload and settings.reload.watchPaths,
			settings.reload and settings.reload.debounceSeconds
		)
	end)
end

local elapsed = math.floor((hs.timer.absoluteTime() - start) / 1000000)
if settings.log and settings.log.startupAlert then
	hs.alert 'Config loaded'
end
if settings.log and settings.log.startupNotification then
	hs.notify.show('Hammerspoon', '', string.format('Initialized in %dms', elapsed))
end
log.i(string.format('Configuration initialized (%dms)', elapsed))
