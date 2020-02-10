-- https://github.com/mhartington/dotfiles/blob/7dafb67c7be40f373e20c3f443216347c20534ea/hammerspoon/init.lua
local modalKey = {'alt'}
local focusKeys = {
  -- [g]oogle chrome
  g='Google Chrome',
  -- [b]rowser (main)
  b='Brave Browser',
  -- [s]lack
  s='Slack',
  -- [t]erminal
  t='Kitty',
  -- tweet[b]ot
  b='Tweetbot',
  -- i[m]essage
  m='Messages',
}

for key in pairs(focusKeys) do
  hs.hotkey.bind(modalKey, key, function()
    hs.application.launchOrFocus(focusKeys[key])
  end)
end

hs.hotkey.bind({}, 'f10', (function()
  hs.alert('Hammerspoon console')
  hs.openConsole()
end))

hs.hotkey.bind(modalKey, 'r', function()
  hs.reload()
end)
