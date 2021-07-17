-- -------------------------------------------------------------------
-- Window managment & Grid
-- -------------------------------------------------------------------

-- https://github.com/wincent/wincent/blob/a33430e43464842c067016e507ab91abd6569948/roles/dotfiles/files/.hammerspoon/init.lua
local lastSeenChain = nil
local lastSeenWindow = nil
local lastSeenAt = nil

hs.grid.setGrid '12x12'
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

local grid = {
  topHalf = '0,0 12x6',
  topThird = '0,0 12x4',
  topTwoThirds = '0,0 12x8',
  rightHalf = '6,0 6x12',
  rightThird = '8,0 4x12',
  rightTwoThirds = '4,0 8x12',
  bottomHalf = '0,6 12x6',
  bottomThird = '0,8 12x4',
  bottomTwoThirds = '0,4 12x8',
  leftHalf = '0,0 6x12',
  leftThird = '0,0 4x12',
  leftTwoThirds = '0,0 8x12',
  topLeft = '0,0 6x6',
  topRight = '6,0 6x6',
  bottomRight = '6,6 6x6',
  bottomLeft = '0,6 6x6',
  fullScreen = '0,0 12x12',
  centeredBig = '3,3 6x6',
  centeredSmall = '4,4 4x4',
}

-- Chain the specified movement commands.
--
-- This is like the 'chain' feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.
--
local function chain(movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if
      lastSeenChain ~= movements
      or lastSeenAt < now - chainResetInterval
      or lastSeenWindow ~= id
    then
      sequenceNumber = 1
      lastSeenChain = movements
    elseif sequenceNumber == 1 then
      -- At end of chain, restart chain on next screen.
      screen = screen:next()
    end
    lastSeenAt = now
    lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber], screen)
    sequenceNumber = sequenceNumber % cycleLength + 1
  end
end

local function alertCannotManipulateWindow()
  hs.alert.show "Can't move window"
end

--
-- Key bindings.
--

hs.hotkey.bind(
  { 'cmd', 'alt' },
  'up',
  chain {
    grid.topHalf,
    grid.topThird,
    grid.topTwoThirds,
  }
)

hs.hotkey.bind(
  { 'cmd', 'alt' },
  'right',
  chain {
    grid.rightHalf,
    grid.rightThird,
    grid.rightTwoThirds,
  }
)

hs.hotkey.bind(
  { 'cmd', 'alt' },
  'down',
  chain {
    grid.bottomHalf,
    grid.bottomThird,
    grid.bottomTwoThirds,
  }
)

hs.hotkey.bind(
  { 'cmd', 'alt' },
  'left',
  chain {
    grid.leftHalf,
    grid.leftThird,
    grid.leftTwoThirds,
  }
)

hs.hotkey.bind(
  { 'alt', 'cmd' },
  'c',
  chain {
    grid.centeredBig,
    grid.centeredSmall,
  }
)

hs.hotkey.bind(
  { 'alt', 'cmd' },
  'f',
  chain {
    grid.fullScreen,
  }
)

hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'left', function()
  local win = hs.window.focusedWindow()
  if not win then
    alertCannotManipulateWindow()
    return
  end
  win:moveOneScreenWest()
end)

hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'right', function()
  local win = hs.window.focusedWindow()
  if not win then
    alertCannotManipulateWindow()
    return
  end
  win:moveOneScreenEast()
end)
