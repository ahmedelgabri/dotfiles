-- Ensure the IPC command line client is available
hs.ipc.cliInstall()
-- disable animations
hs.window.animationDuration = 0

hs.application.enableSpotlightForNameSearches(true)
hs.loadSpoon('SpoonInstall')

Install = spoon.SpoonInstall

require 'mappings'
require 'layout'

Install:andUse('WindowHalfsAndThirds', {
    config = {
      use_frame_correctness = true
    },
  })

-- Muscle memory from  Spectacle
spoon.WindowHalfsAndThirds:bindHotkeys({
    max =  { {"cmd", "alt"}, "f" },
    left_half =  { {"cmd", "alt"}, "Left" },
    right_half =  { {"cmd", "alt"}, "Right" },
    bottom_half =  { {"cmd", "alt"}, "Down" },
    top_half =  { {"cmd", "alt"}, "Up" }
  })

Install:andUse('WindowScreenLeftAndRight',  {
    hotkeys =  'default'
  })

Install:andUse('Caffeine', {
    start = true,
  })


local urlDispatcherConfig = {
  start = true,
  config = {
    default_handler = 'com.google.Chrome'
  }
}

if hs.host.localizedName() ~= 'pandoras-box' then
  urlDispatcherConfig.config = {
    url_patterns = {
      {'https?://miro.*','com.google.Chrome'},
      {'https?://dev.*.com','com.google.Chrome'},
      {'https?://localhost:*','com.google.Chrome'}
    },
    default_handler = 'com.brave.Browser'
  }
end

Install:andUse('URLDispatcher', urlDispatcherConfig)

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
