-- Ensure the IPC command line client is available
hs.ipc.cliInstall()
hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon('SpoonInstall')

require 'mappings'
require 'window-managment'
require 'layout'
amphetamine = require 'amphetamine'

local default_browser = hs.host.localizedName() == 'Pandoras-Box' and 'com.google.Chrome.Canary' or 'com.brave.Browser'

spoon.SpoonInstall.use_syncinstall = true

spoon.SpoonInstall:andUse('URLDispatcher',
  {
    config = {
      url_patterns = {
        { 'https?://jira.atlightspeed.net', 'com.google.Chrome' },
        { 'https?://confluence.atlightspeed.net', 'com.google.Chrome' },
        { 'https?://%w-%.-github%.com/SEOshop',  'com.google.Chrome' },
        { 'https?://github.com/merchantos',  'com.google.Chrome' },
        { 'https?://github.com/lightspeedretail',  'com.google.Chrome' },
        { 'https?://circleci.com/gh/lightspeedretail',  'com.google.Chrome' },
        { 'https?://circleci.com/gh/SEOshop',  'com.google.Chrome' },
        { 'https?://circleci.com/gh/merchantos',  'com.google.Chrome' },
      },
      default_handler = default_browser
    },
    start = true
  }
)


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
