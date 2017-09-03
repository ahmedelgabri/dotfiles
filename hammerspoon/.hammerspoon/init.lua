-- Ensure the IPC command line client is available
hs.ipc.cliInstall()

require 'mappings'
require 'window-managment'
require 'spoons'

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
