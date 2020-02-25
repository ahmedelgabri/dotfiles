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


--
-- Screens
--

local screens = {
  main = hs.screen("Color LCD"),
  thunderbolt = hs.screen("Thunderbolt Display"),
  dell = hs.screen("DELL U2717D"),
}

--
-- Layouts
--

local threeMonitors = {
  {apps.chrome, nil, screens.thunderbolt, hs.layout.maximized, nil, nil},
  {apps.tweetbot, nil, screens.dell, hs.layout.left50, nil, nil},
  {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil},
  -- {apps.brave, nil, screens.main, hs.layout.maximized, nil, nil},
  -- {apps.terminal, nil, screens.main, hs.layout.maximized, nil, nil},
}

local twoThunderbot = {
  {apps.chrome, nil, screens.thunderbolt, hs.layout.maximized, nil, nil},
  {apps.tweetbot, nil, screens.main, hs.layout.right30, nil, nil},
  {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil},
}

local twoDell = {
  {apps.chrome, nil, screens.dell, hs.layout.maximized, nil, nil},
  {apps.tweetbot, nil, screens.dell, hs.layout.right50, nil, nil},
  {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil},
}

---
-- Screen watcher
---

function switchLayout()
  local allScreens = hs.screen.allScreens()
  local contains = hs.fnutils.contains

  if #allScreens == 3 and contains(allScreens, screens.main) and contains(allScreens, screens.thunderbolt) and contains(allScreens, screens.dell) then
    -- hs.alert.show(#allScreens .. ' monitors layout activated')
    hs.layout.apply(threeMonitors)
  elseif #allScreens == 2 and contains(allScreens, screens.main) and contains(allScreens, screens.thunderbolt) then
    -- hs.alert.show(#allScreens .. ' monitors: ' .. screens.thunderbolt:name() .. ' layout activated')
    hs.layout.apply(twoThunderbot)
  elseif #allScreens == 2 and contains(allScreens, screens.main) and contains(allScreens, screens.dell) then
    -- hs.alert.show(#allScreens .. ' monitors: ' .. screens.dell:name() .. ' layout activated')
    hs.layout.apply(twoDell)
  else
    return
  end
end


local layoutWatcher = hs.screen.watcher.newWithActiveScreen(switchLayout)
layoutWatcher:start()
