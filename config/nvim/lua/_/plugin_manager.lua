local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	}
end

vim.opt.rtp:prepend(lazypath)

return require('lazy').setup('plugins', {
	dev = {
		-- directory where you store your local plugin projects
		path = '~/Sites/personal/forks',
		---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
		patterns = { 'ahmedelgabri' }, -- For example {"folke"}
		fallback = true, -- Fallback to git when local plugin doesn't exist
	},
	ui = {
		icons = {
			cmd = '⌘',
			config = '🛠',
			event = '📅',
			ft = '📂',
			init = '⚙',
			keys = '🗝',
			plugin = '🔌',
			runtime = '💻',
			source = '📄',
			start = '🚀',
			task = '📌',
			lazy = '💤 ',
		},
	},
})
