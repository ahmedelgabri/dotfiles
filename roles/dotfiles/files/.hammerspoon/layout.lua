-- -------------------------------------------------------------------
-- Layout managment
-- -------------------------------------------------------------------

--
-- Apps
--

local apps = {
  brave = 'Brave Browser',
  chrome = 'Google Chrome',
  slack = 'Slack',
  tweetbot = 'Tweetbot',
  terminal = 'Kitty',
}

---
-- Screen watcher
---

function SwitchLayout()
  local allScreens = hs.screen.allScreens()
  local moreThanOneScreen = #allScreens > 1
  local isTwoScreens = #allScreens == 2
  local contains = hs.fnutils.contains

  local screens = {
    main = hs.screen("Color LCD"), -- MBP screen
    samsung = hs.screen("S24R65x"),
  }

  local layout = {
    { apps.chrome  , nil, (isTwoScreens and contains(allScreens, screens.samsung)) and screens.samsung or screens.main, hs.layout.maximized, nil, nil },
    { apps.tweetbot, nil, screens.main                                                                                , hs.layout.right30  , nil, nil },
    { apps.slack   , nil, screens.main                                                                                , hs.layout.maximized, nil, nil },
    { apps.brave   , nil, screens.main                                                                                , hs.layout.maximized, nil, nil },
  }

  if (moreThanOneScreen) then
    hs.notify.show("Hammerspoon", #allScreens .. " monitor layout activated", screens.samsung:name() or screens.main:name())
  end

  hs.layout.apply(layout)
end

-- SwitchLayout()

local layoutWatcher = hs.screen.watcher.newWithActiveScreen(SwitchLayout)
layoutWatcher:start()
