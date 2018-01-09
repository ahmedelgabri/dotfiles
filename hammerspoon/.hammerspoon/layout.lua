-- -------------------------------------------------------------------
-- Layout managment
-- -------------------------------------------------------------------

--
-- Apps
--

local apps = {
  -- canary = 'Google Chrome Canary',
  -- stable = 'Google Chrome',
  -- Let's see if this will select Stable Google Chrome right or will confuse it with Canary still
  stable = hs.application.applicationsForBundleID('com.google.Chrome')[1],
  slack = 'Slack',
  tweetbot = 'Tweetbot',
  -- iterm = 'iTerm',
}


--
-- Screens
--

local screens = {
  main = hs.screen("Color LCD"),
  thunderbolt = hs.screen("Thunderbolt Display"),
  dell = hs.screen("DELL P2714H"),
}

--
-- Layouts
--

local threeMonitors = {
  {apps.stable, nil, screens.thunderbolt, hs.layout.maximized, nil, nil},
  {apps.tweetbot, nil, screens.dell, hs.layout.right50, nil, nil},
  {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil},
  -- {apps.canary, nil, screens.main, hs.layout.maximized, nil, nil},
  -- {apps.iterm, nil, screens.main, hs.layout.maximized, nil, nil},
}

local twoThunderbot = {
  {apps.stable, nil, screens.thunderbolt, hs.layout.maximized, nil, nil},
  {apps.tweetbot, nil, screens.main, hs.layout.right30, nil, nil},
  {apps.slack, nil, screens.main, hs.layout.maximized, nil, nil},
}

local twoDell = {
  {apps.stable, nil, screens.dell, hs.layout.maximized, nil, nil},
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
    hs.alert.show(#allScreens .. ' monitors layout activated')
    hs.layout.apply(threeMonitors)
  elseif #allScreens == 2 and contains(allScreens, screens.main) and contains(allScreens, screens.thunderbolt) then
    hs.alert.show(#allScreens .. ' monitors: ' .. screens.thunderbolt:name() .. ' layout activated')
    hs.layout.apply(twoThunderbot)
  elseif #allScreens == 2 and contains(allScreens, screens.main) and contains(allScreens, screens.dell) then
    hs.alert.show(#allScreens .. ' monitors: ' .. screens.dell:name() .. ' layout activated')
    hs.layout.apply(twoDell)
  else
    return
  end
end


local layoutWatcher = hs.screen.watcher.new(switchLayout)
layoutWatcher:start()

