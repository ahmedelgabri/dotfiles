hs.loadSpoon('SpoonInstall')

-- This draws a bright red circle around the pointer for a few seconds
spoon.SpoonInstall:andUse('MouseCircle', { 
    hotkeys = { 
      show = { {'ctrl', 'alt'}, 'space' }
    },
  })

spoon.SpoonInstall:andUse('Caffeine',
  { 
    hotkeys = { 
      toggle = { {'ctrl', 'alt'}, 'c' }
    },
    start = true,
  })

-- Draw pretty rounded corners on all screens
spoon.SpoonInstall:andUse('RoundedCorners', { start = true })

