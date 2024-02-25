-- https://yazi-rs.github.io/docs/tips#smart-enter-enter-for-directory-open-for-file
return {
	entry = function()
		local h = cx.active.current.hovered
		ya.manager_emit(h and h.cha.is_dir and 'enter' or 'open', {})
	end,
}
