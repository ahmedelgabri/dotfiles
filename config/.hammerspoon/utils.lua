local M = {}

function M.deepMerge(tbl1, tbl2)
	for k, v in pairs(tbl2) do
		if type(v) == 'table' and type(tbl1[k]) == 'table' then
			-- If it's a list, then concat
			if v[1] ~= nil and tbl1[k][1] ~= nil then
				tbl1[k] = hs.fnutils.concat(tbl1[k], v)
			else
				-- Otherwise it's a map
				tbl1[k] = M.deepMerge(tbl1[k], v)
			end
		else
			tbl1[k] = v
		end
	end
	return tbl1
end

-- Returns the bundle ID of an application, given its path.
function M.appID(app)
	if hs.application.infoForBundlePath(app) then
		return hs.application.infoForBundlePath(app)['CFBundleIdentifier']
	end
end

M.appMap = {
	-- Browsers
	chrome = M.appID '/Applications/Chrome.app',
	firefox = M.appID '/Applications/Firefox.app',
	zen = M.appID '/Applications/Zen Browser.app',
	safari = M.appID '/Applications/Safari.app',

	-- Terminals
	kitty = M.appID '/Applications/kitty.app',
	ghostty = M.appID '/Applications/Ghostty.app',

	-- Socials
	-- Both suck
	x = M.appID '/Applications/X.app'
		or M.appID '~/Applications/Chrome Apps.localized/X.app',
	-- bluesky = 'dev.mozzius.graysky',

	-- Chat
	discord = M.appID '/Applications/Discord.app',
	slack = M.appID '/Applications/Slack.app',
	imessage = M.appID '/System/Applications/Messages.app',

	-- Productivity
	calendar = M.appID '/Applications/Notion Calendar.app',
	['1password'] = M.appID '/Applications/1Password.app',

	-- Meetings
	zoom = M.appID '/Applications/zoom.us.app',
	meet = M.appID '~/Applications/Chrome Apps.localized/Google Meet.app',
}

return M
