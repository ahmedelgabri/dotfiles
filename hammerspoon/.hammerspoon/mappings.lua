-- https://github.com/mhartington/dotfiles/blob/7dafb67c7be40f373e20c3f443216347c20534ea/hammerspoon/init.lua
local modalKey = {'alt'}
local focusKeys = {
  b='Google Chrome',
  g='Google Chrome Canary',
  s='Slack',
  i='iTerm',
  t='Tweetbot',
  m='Messages',
}

for key in pairs(focusKeys) do
  hs.hotkey.bind(modalKey, key, function()
    hs.application.launchOrFocus(focusKeys[key])
  end)
end

-- lock screen
-- Old: https://www.isi.edu/~calvin/mac-lockscreen.htm
-- Curent: https://github.com/sindresorhus/macos-lock
hs.hotkey.bind({'ctrl', 'cmd', 'alt'}, 'l', function()
  os.execute('/Users/ahmed/.dotfiles/bin/lock')
end)

hs.hotkey.bind({}, '§', function()
  hs.eventtap.keyStroke({}, 'ESCAPE')
end)

hs.hotkey.bind({}, 'f10', (function()
  hs.alert('Hammerspoon console')
  hs.openConsole()
end))

hs.hotkey.bind(modalKey, 'r', function()
  hs.reload()
end)


