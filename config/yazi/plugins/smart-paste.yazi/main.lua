-- https://yazi-rs.github.io/docs/tips/#smart-paste
--- @sync entry
return {
	entry = function()
		local h = cx.active.current.hovered

		if h and h.cha.is_dir then
			ya.emit('enter', {})
			ya.emit('paste', {})
			ya.emit('leave', {})
		else
			ya.emit('paste', {})
		end
	end,
}
