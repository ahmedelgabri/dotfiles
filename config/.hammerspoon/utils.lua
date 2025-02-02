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

local firefox = M.appID '/Applications/Firefox.app'
local ghostty = M.appID '/Applications/Ghostty.app'

M.appMap = {
	chrome = M.appID '/Applications/Chrome.app',
	firefox = firefox,
	slack = M.appID '/Applications/Slack.app',
	x = M.appID '/Applications/X.app',
	-- bluesky = 'dev.mozzius.graysky',
	kitty = M.appID '/Applications/kitty.app',
	ghostty = ghostty,
	discord = M.appID '/Applications/Discord.app',

	browser = firefox,
	terminal = ghostty,
	imessage = M.appID '/System/Applications/Messages.app',
	calendar = M.appID '/Applications/Notion Calendar.app',
}

return M
