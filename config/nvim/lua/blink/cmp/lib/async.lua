-- Compat shim so plugins still expecting blink.cmp v1's `blink.cmp.lib.async`
-- (e.g. blink-emoji.nvim) keep working with blink.cmp v2, which moved the task
-- primitives to `blink.lib.task`.
local lib_task = require 'blink.lib.task'

return {
	task = setmetatable({
		empty = function()
			return lib_task.resolve()
		end,
	}, { __index = lib_task }),
}
