-- Ensure the IPC command line client is available
hs.ipc.cliInstall()
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon('SpoonInstall')

require 'mappings'
require 'window-managment'
require 'layout'
Amphetamine = require 'amphetamine'

local urlDispatcherConfig = {
  start = true,
  config = {
    default_handler = 'com.google.Chrome'
  }
}

if hs.host.localizedName() ~= 'pandoras-box' then
  urlDispatcherConfig.config = {
    url_patterns = {
      {'https?://.*.devrtb.com','com.google.Chrome'}
    },
    default_handler = 'com.brave.Browser'
  }
end

spoon.SpoonInstall:andUse('URLDispatcher', urlDispatcherConfig)

--
-- Auto-reload config on change.
--

function ReloadConfig(files)
  local doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

MyWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", ReloadConfig):start()

hs.alert("Config loaded")
