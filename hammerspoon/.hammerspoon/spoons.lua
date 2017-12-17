hs.loadSpoon('SpoonInstall')

spoon.SpoonInstall:andUse('Caffeine',
  {
    hotkeys = {
      toggle = { {'ctrl', 'alt'}, 'c' }
    },
    start = true,
  })

-- Draw pretty rounded corners on all screens
spoon.SpoonInstall:andUse('RoundedCorners', { start = true })

