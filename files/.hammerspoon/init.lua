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
          { 'https?://.*SEOshop.*',  'com.google.Chrome' },
          { 'https?://.*merchantos.*',  'com.google.Chrome' },
          { 'https?://.*lightspeed.*',  'com.google.Chrome' },
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

function reloadConfig(paths)
  doReload = false
  for _,file in pairs(paths) do
    if file:sub(-4) == '.lua' then
      print('A lua file changed, doing reload')
      doReload = true
    end
  end
  if not doReload then
    print('No lua file changed, skipping reload')
    return
  end

  hs.reload()
end

local configFileWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig)
configFileWatcher:start()
hs.alert.show('Config loaded')
