local utils = require 'utils'
local M = {}
-- -------------------------------------------------------------------
-- Layout management
-- -------------------------------------------------------------------
M.screens = {
	main = hs.screen.primaryScreen(),
	samsung = hs.screen 'S24R65x',
	LG = hs.screen 'LG HDR 4K',
}

---
-- Screen watcher
---

function M.switchLayout()
	local allScreens = hs.screen.allScreens()
	local moreThanOneScreen = #allScreens > 1
	local contains = hs.fnutils.contains

	local layout = {
		{
			utils.appMap.chrome,
			nil,
			(moreThanOneScreen and (contains(allScreens, M.screens.LG) or contains(
				allScreens,
				M.screens.samsung
			))) and (M.screens.LG or M.screens.samsung) or M.screens.main,
			hs.layout.maximized,
			nil,
			nil,
		},
		{ utils.appMap.x, nil, M.screens.main, hs.layout.right30, nil, nil },
		{ utils.appMap.slack, nil, M.screens.main, hs.layout.maximized, nil, nil },
		-- {
		--   appMap.brave,
		--   nil,
		--   screens.main,
		--   hs.layout.maximized,
		--   nil,
		--   nil
		-- }
	}

	if moreThanOneScreen then
		hs.notify.show(
			'Hammerspoon',
			#allScreens .. ' monitor layout activated',
			(M.screens.LG or M.screens.samsung or M.screens.main):name()
		)
	end

	hs.layout.apply(layout)
end

function M.setup()
	M.switchLayout()
	M.layoutWatcher = hs.screen.watcher.newWithActiveScreen(M.switchLayout)
	M.layoutWatcher:start()
end

return M
