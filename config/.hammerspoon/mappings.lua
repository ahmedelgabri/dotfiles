-- https://github.com/mhartington/dotfiles/blob/7dafb67c7be40f373e20c3f443216347c20534ea/hammerspoon/init.lua
local modalKey = { 'alt' }
local focusKeys = {
  -- [g]oogle chrome
  g = 'Google Chrome',
  -- [b]rowser (main)
  b = 'Brave Browser',
  -- [s]lack
  s = 'Slack',
  -- [t]erminal
  t = 'open -a kitty',
  -- tweet[b]ot
  -- b='Tweetbot',
  -- i[m]essage
  m = 'Messages',
}

for key in pairs(focusKeys) do
  hs.hotkey.bind(modalKey, key, function()
    if key == 't' then
      hs.execute(focusKeys[key])
    else
      hs.application.launchOrFocus(focusKeys[key])
    end
  end)
end

hs.hotkey.bind({}, 'f10', hs.openConsole)

--  Mute Zoom (requires enabling global keyboard shortcut in Zoom)
hs.hotkey.bind({}, '§', function()
  hs.eventtap.keyStroke({ 'CMD', 'SHIFT' }, 'a')
end)

hs.hotkey.bind(modalKey, 'r', function()
  hs.reload()
end)
