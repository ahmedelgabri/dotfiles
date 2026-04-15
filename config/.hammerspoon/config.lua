local tempLocationPath = hs.fs.temporaryDirectory() .. '.location.json'

return {
	log = {
		level = 'info',
		startupAlert = true,
		startupNotification = true,
	},

	features = {
		autoReload = true,
		spoons = true,
		layout = false,
		wifiWatcher = true,
		location = true,
		setSystemBrowserHandler = true,
	},

	reload = {
		watchPaths = nil,
		debounceSeconds = 0.5,
	},

	location = {
		outputPath = tempLocationPath,
		initialLookupDelaySeconds = 1,
		debounceSeconds = 5,
	},

	wifi = {
		notifyOnChange = true,
		notifyInitial = false,
	},

	layout = {
		debounceSeconds = 0.75,
		notifyOnApply = true,
		preferredExternalNames = {
			'LG HDR 4K',
			'S24R65x',
		},
	},

	hotkeys = {
		hyper = { 'shift', 'ctrl', 'alt', 'cmd' },
		layerOverlay = {
			enabled = true,
		},
		reload = {
			mods = { 'alt', 'cmd' },
			key = 'r',
		},
		console = {
			mods = {},
			key = 'f10',
		},
		meetingMute = {
			mods = {},
			key = '§',
			activationDelaySeconds = 0.2,
			restorePreviousApp = false,
		},
	},

	apps = {
		chrome = {
			paths = {
				'/Applications/Google Chrome.app',
				'/Applications/Chrome.app',
			},
			bundleIDs = { 'com.google.Chrome' },
		},
		firefox = {
			paths = { '/Applications/Firefox.app' },
			bundleIDs = { 'org.mozilla.firefox' },
		},
		zen = {
			paths = { '/Applications/Zen Browser.app' },
			bundleIDs = { 'app.zen-browser.zen' },
		},
		safari = {
			paths = {
				'/Applications/Safari.app',
				'/System/Applications/Safari.app',
			},
			bundleIDs = { 'com.apple.Safari' },
		},
		kitty = {
			paths = { '/Applications/kitty.app' },
			bundleIDs = { 'net.kovidgoyal.kitty' },
		},
		ghostty = {
			paths = { '/Applications/Ghostty.app' },
			bundleIDs = { 'com.mitchellh.ghostty' },
		},
		x = {
			paths = {
				'/Applications/X.app',
				'~/Applications/Chrome Apps.localized/X.app',
			},
			bundleIDs = {},
		},
		discord = {
			paths = { '/Applications/Discord.app' },
			bundleIDs = { 'com.hnc.Discord' },
		},
		slack = {
			paths = { '/Applications/Slack.app' },
			bundleIDs = { 'com.tinyspeck.slackmacgap' },
		},
		imessage = {
			paths = { '/System/Applications/Messages.app' },
			bundleIDs = { 'com.apple.MobileSMS' },
		},
		calendar = {
			paths = { '/Applications/Notion Calendar.app' },
			bundleIDs = { 'notion.id.calendar' },
		},
		['1password'] = {
			paths = { '/Applications/1Password.app' },
			bundleIDs = { 'com.1password.1password' },
		},
		zoom = {
			paths = { '/Applications/zoom.us.app' },
			bundleIDs = { 'us.zoom.xos' },
		},
		meet = {
			paths = { '~/Applications/Chrome Apps.localized/Google Meet.app' },
			bundleIDs = {},
		},
	},

	spoons = {
		loadEmmyLua = false,
		urlDispatcherLogLevel = 'warning',
	},

	urls = {
		defaultBrowserPriority = {
			'firefox',
			'zen',
			'safari',
			'chrome',
		},
		dispatchRules = {
			{ 'https?://%w+.zoom.us/j/', 'zoom' },
		},
		redirectDecoders = {
			{
				'redirect old NixOS wiki',
				'https://nixos%.wiki/(.*)',
				'https://wiki.nixos.org/%1',
			},
		},
	},
}
