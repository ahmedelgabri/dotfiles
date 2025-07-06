local au = require '_.utils.au'

local function set_macos_colorscheme()
	if vim.loop.os_uname().sysname ~= 'Darwin' then
		vim.o.background = 'dark'
		print 'Not macOS, switch to Dark mode as default.'
	end
	local appleInterfaceStyle =
		vim.fn.system { 'defaults', 'read', '-g', 'AppleInterfaceStyle' }

	-- The not is because in light mode (which is the default) you get
	-- "The domain/default pair of (kCFPreferencesAnyApplication, AppleInterfaceStyle) does not exist"
	if not appleInterfaceStyle:find 'Dark' then
		vim.o.background = 'light'
		print 'Switched to Light Mode'
	else
		vim.o.background = 'dark'
		print 'Switched to Dark Mode'
	end
end

au.augroup('__MyCustomColors__', {
	{
		event = { 'VimEnter', 'FocusGained' },
		callback = set_macos_colorscheme,
		desc = 'Set colorscheme based on macOS appearance',
	},
	{
		event = { 'UIEnter', 'ColorScheme' },
		callback = function()
			local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
			if not normal.bg then
				return
			end

			if vim.env.TMUX then
				io.write(
					string.format('\027Ptmux;\027\027]11;#%06x\007\027\\', normal.bg)
				)
			else
				io.write(string.format('\027]11;#%06x\027\\', normal.bg))
			end
		end,
	},
	{
		event = 'UILeave',
		callback = function()
			if vim.env.TMUX then
				io.write '\027Ptmux;\027\027]111;\007\027\\'
			else
				io.write '\027]111\027\\'
			end
		end,
	},
})

vim.cmd.colorscheme 'plain'
