-- sidekick.nvim: AI assistant (lazy on keys)
-- TODO: Change keymaps for LSP to start with <leader>l to avoid conflicts

local pack = require 'plugins.pack'

local function ensure_sidekick()
	return pack.setup('sidekick.nvim', 'sidekick.nvim', function()
		require('sidekick').setup {
			mux = { enabled = true },
		}
	end)
end

vim.keymap.set({ 'n', 't', 'i', 'x' }, '<LocalLeader>cc', function()
	if ensure_sidekick() then
		require('sidekick.cli').toggle()
	end
end, { desc = 'Sidekick Toggle' })

vim.keymap.set('n', '<localleader>aa', function()
	if ensure_sidekick() then
		require('sidekick.cli').toggle()
	end
end, { desc = 'Sidekick Toggle CLI' })

vim.keymap.set('n', '<localleader>as', function()
	if ensure_sidekick() then
		require('sidekick.cli').select { filter = { installed = true } }
	end
end, { desc = 'Select CLI' })

vim.keymap.set({ 'x', 'n' }, '<localleader>at', function()
	if ensure_sidekick() then
		require('sidekick.cli').send { msg = '{this}' }
	end
end, { desc = 'Send This' })

vim.keymap.set('n', '<localleader>af', function()
	if ensure_sidekick() then
		require('sidekick.cli').send { msg = '{file}' }
	end
end, { desc = 'Send File' })

vim.keymap.set('x', '<localleader>av', function()
	if ensure_sidekick() then
		require('sidekick.cli').send { msg = '{selection}' }
	end
end, { desc = 'Send Visual Selection' })

vim.keymap.set({ 'n', 'x' }, '<localleader>ap', function()
	if ensure_sidekick() then
		require('sidekick.cli').prompt()
	end
end, { desc = 'Sidekick Select Prompt' })
