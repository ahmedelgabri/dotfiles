hs.loadSpoon 'SpoonInstall'

local utils = require 'utils'

local M = {}

local urlDispatcherConfig = {
	start = true,
	config = {
		default_handler = utils.appMap.firefox,
		decode_slack_redir_urls = true,
		set_system_handler = true,
		url_patterns = {
			-- App links
			{ 'https?://%w+.zoom.us/j/', 'us.zoom.xos' },
		},
		url_redir_decoders = {
			'redirect old NixOS wiki',
			'https://nixos%.wiki/(.*)',
			'https://wiki.nixos.org/$1',
		},
	},
}

function M.setup()
	M.install = spoon.SpoonInstall
	M.install:updateAllRepos()

	M.install:andUse 'EmmyLua'
	-- ╔════════╗
	-- ║Caffeine║
	-- ╚════════╝
	M.install:andUse('Caffeine', {
		start = true,
	})

	-- ╔═════════════╗
	-- ║URLDispatcher║
	-- ╚═════════════╝
	M.install:andUse('URLDispatcher', urlDispatcherConfig)
	spoon.URLDispatcher.logger.setLogLevel 'debug'
end

return M
