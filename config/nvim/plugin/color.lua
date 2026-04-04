local au = require '_.utils.au'

local function set_macos_colorscheme()
	if vim.uv.os_uname().sysname ~= 'Darwin' then
		vim.o.background = 'dark'
		return
	end

	local appleInterfaceStyle =
		vim.fn.system { 'defaults', 'read', '-g', 'AppleInterfaceStyle' }

	-- The not is because in light mode (which is the default) you get
	-- "The domain/default pair of (kCFPreferencesAnyApplication, AppleInterfaceStyle) does not exist"
	if not appleInterfaceStyle:find 'Dark' then
		vim.o.background = 'light'
	else
		vim.o.background = 'dark'
	end
end

au.augroup('__MyCustomColors__', {
	{
		event = { 'VimEnter', 'FocusGained' },
		callback = set_macos_colorscheme,
		desc = 'Set colorscheme based on macOS appearance',
	},
})

vim.cmd.colorscheme 'plain'
