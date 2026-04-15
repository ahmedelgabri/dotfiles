-- -------------------------------------------------------------------
-- Window management & Grid
-- -------------------------------------------------------------------

local M = {}
local log = require 'log'

local state = {
	lastSeenChain = nil,
	lastSeenWindow = nil,
	lastSeenAt = 0,
}

hs.grid.ui.textSize = 24
hs.grid.ui.fontName = 'PragmataPro Mono'

hs.grid.setGrid '12x12'
hs.grid.setMargins(hs.geometry.size(0, 0))

M.grid = {
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

local function getFocusedWindow()
	local win = hs.window.frontmostWindow()
	if not win then
		log.w 'No focused window available'
		return nil
	end

	return win
end

local function withFocusedWindow(fn)
	local win = getFocusedWindow()
	if not win then
		return false
	end

	return fn(win)
end

local function makeChain(movements)
	local chainResetInterval = 2 -- seconds
	local cycleLength = #movements
	local sequenceNumber = 1

	return function()
		withFocusedWindow(function(win)
			local id = win:id()
			local now = hs.timer.secondsSinceEpoch()
			local screen = win:screen()
			if not screen then
				log.w "Can't determine window screen"
				return false
			end

			if
				state.lastSeenChain ~= movements
				or state.lastSeenAt == 0
				or state.lastSeenAt < now - chainResetInterval
				or state.lastSeenWindow ~= id
			then
				sequenceNumber = 1
				state.lastSeenChain = movements
			elseif sequenceNumber == 1 then
				screen = screen:next() or screen
			end

			state.lastSeenAt = now
			state.lastSeenWindow = id

			hs.grid.set(win, movements[sequenceNumber], screen)
			sequenceNumber = sequenceNumber % cycleLength + 1
			return true
		end)
	end
end

local function moveFocusedWindowToScreen(direction)
	withFocusedWindow(function(win)
		if direction == 'west' then
			win:moveOneScreenWest(false, true)
		else
			win:moveOneScreenEast(false, true)
		end
		return true
	end)
end

function M.setup()
	hs.hotkey.bind(
		{ 'cmd', 'alt' },
		'up',
		makeChain {
			M.grid.topHalf,
			M.grid.topThird,
			M.grid.topTwoThirds,
		}
	)

	hs.hotkey.bind(
		{ 'cmd', 'alt' },
		'right',
		makeChain {
			M.grid.rightHalf,
			M.grid.rightThird,
			M.grid.rightTwoThirds,
		}
	)

	hs.hotkey.bind(
		{ 'cmd', 'alt' },
		'down',
		makeChain {
			M.grid.bottomHalf,
			M.grid.bottomThird,
			M.grid.bottomTwoThirds,
		}
	)

	hs.hotkey.bind(
		{ 'cmd', 'alt' },
		'left',
		makeChain {
			M.grid.leftHalf,
			M.grid.leftThird,
			M.grid.leftTwoThirds,
		}
	)

	hs.hotkey.bind(
		{ 'alt', 'cmd' },
		'c',
		makeChain {
			M.grid.centeredBig,
			M.grid.centeredSmall,
		}
	)

	hs.hotkey.bind(
		{ 'alt', 'cmd' },
		'f',
		makeChain {
			M.grid.fullScreen,
		}
	)

	hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'left', function()
		moveFocusedWindowToScreen 'west'
	end)

	hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'right', function()
		moveFocusedWindowToScreen 'east'
	end)
end

return M
