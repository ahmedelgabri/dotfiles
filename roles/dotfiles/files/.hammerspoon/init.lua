-- Ensure the IPC command line client is available
hs.ipc.cliInstall()
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon('SpoonInstall')

require 'mappings'
require 'window-managment'
require 'layout'
amphetamine = require 'amphetamine'

spoon.SpoonInstall.use_syncinstall = true

if hs.host.localizedName() == 'pandoras-box' then
  spoon.SpoonInstall:andUse('URLDispatcher',
    {
      config = {
        url_patterns = {
          { 'https?://zoom.us/j/*', 'zoom.us.app' }
        },
        default_handler = 'com.google.Chrome'
      },
      start = true
    }
    )
else
  spoon.SpoonInstall:andUse('URLDispatcher',
    {
      config = {
        url_patterns = {
          { 'https?://zoom.us/j/*', 'zoom.us.app' }
        },
        default_handler = 'com.brave.Browser'
      },
      start = true
    }
    )
end


--
-- Auto-reload config on change.
--

function reloadConfig(files)
  doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")
