-- -------------------------------------------------------------------
-- Layout managment
-- -------------------------------------------------------------------

--
-- Apps
--

local apps = {
  brave = "Brave Browser",
  chrome = "Google Chrome",
  slack = "Slack",
  tweetbot = "Tweetbot",
  terminal = "Kitty"
}

---
-- Screen watcher
---

local function SwitchLayout()
  local allScreens = hs.screen.allScreens()
  local moreThanOneScreen = #allScreens > 1
  local isTwoScreens = #allScreens == 2
  local contains = hs.fnutils.contains

  local screens = {
    main = hs.screen("Color LCD"), -- MBP screen
    samsung = hs.screen("S24R65x"),
    LG = hs.screen("LG HDR 4K")
  }

  local layout = {
    {
      apps.chrome,
      nil,
      (moreThanOneScreen and
        (contains(allScreens, screens.LG) or
          contains(allScreens, screens.samsung))) and
        (screens.LG or screens.samsung) or
        screens.main,
      hs.layout.maximized,
      nil,
      nil
    },
    {apps.tweetbot, nil, screens.main, hs.layout.right30, nil, nil},
    {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil}
    -- {
    --   apps.brave,
    --   nil,
    --   screens.main,
    --   hs.layout.maximized,
    --   nil,
    --   nil
    -- }
  }

  if (moreThanOneScreen) then
    hs.notify.show(
      "Hammerspoon",
      #allScreens .. " monitor layout activated",
      (screens.LG or screens.samsung or screens.main):name()
    )
  end

  hs.layout.apply(layout)
end

SwitchLayout()

return {
  layoutWatcher = hs.screen.watcher.newWithActiveScreen(SwitchLayout)
}
