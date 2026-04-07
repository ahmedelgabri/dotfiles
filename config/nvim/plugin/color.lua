local au = require '_.utils.au'

local function set_macos_colorscheme()
	if vim.uv.os_uname().sysname ~= 'Darwin' then
		vim.o.background = 'dark'
		return
	end

	vim.system(
		{ 'defaults', 'read', '-g', 'AppleInterfaceStyle' },
		{ text = true },
		vim.schedule_wrap(function(obj)
			-- In light mode (the default) the key doesn't exist, so stdout won't contain "Dark"
			if obj.stdout and obj.stdout:find 'Dark' then
				vim.o.background = 'dark'
			else
				vim.o.background = 'light'
			end
		end)
	)
end

au.augroup('__MyCustomColors__', {
	{
		event = 'FocusGained',
		callback = set_macos_colorscheme,
		desc = 'Set colorscheme based on macOS appearance',
	},
})

-- Run async on startup too
set_macos_colorscheme()

vim.cmd.colorscheme 'plain'
