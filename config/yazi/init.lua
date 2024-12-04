---@diagnostic disable: undefined-global

require('full-border'):setup()
require('git'):setup()

---@return unknown
-- https://yazi-rs.github.io/docs/tips#show-symlink-in-status-bar
function Status:name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span ''
	end

	local linked = ''
	if h.link_to ~= nil then
		linked = ' -> ' .. tostring(h.link_to)
	end
	return ui.Span(' ' .. h.name .. linked)
end

-- https://yazi-rs.github.io/docs/tips#show-usergroup-of-files-in-status-bar
function Status:owner()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= 'unix' then
		return ui.Line {}
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg 'magenta',
		ui.Span ':',
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg 'magenta',
		ui.Span ' ',
	}
end
