-- -------------------------------------------------------------------
-- Layout management
-- -------------------------------------------------------------------
local screens = {
	main = hs.screen.primaryScreen(),
	samsung = hs.screen 'S24R65x',
	LG = hs.screen 'LG HDR 4K',
}

--
-- Apps
--

local appMap = {
	'com.google.Chrome',
	'org.mozilla.firefox',
	'com.tinyspeck.slackmacgap',
	'com.google.Chrome.app.lodlkdfmihgonocnmddehnfgiljnadcf', -- X  Chrome App
	'net.kovidgoyal.kitty',
	'com.github.wez.wezterm',
	'com.hnc.Discord',
}

---
-- Screen watcher
---

local function SwitchLayout()
	local allScreens = hs.screen.allScreens()
	local moreThanOneScreen = #allScreens > 1
	local contains = hs.fnutils.contains

	local layout = {
		{
			appMap.chrome,
			nil,
			(moreThanOneScreen and (contains(allScreens, screens.LG) or contains(
				allScreens,
				screens.samsung
			))) and (screens.LG or screens.samsung) or screens.main,
			hs.layout.maximized,
			nil,
			nil,
		},
		{ appMap.twitter, nil, screens.main, hs.layout.right30, nil, nil },
		{ appMap.tweetbot, nil, screens.main, hs.layout.right30, nil, nil },
		{ appMap.slack, nil, screens.main, hs.layout.maximized, nil, nil },
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
			(screens.LG or screens.samsung or screens.main):name()
		)
	end

	hs.layout.apply(layout)
end

SwitchLayout()

return {
	layoutWatcher = hs.screen.watcher.newWithActiveScreen(SwitchLayout),
}
