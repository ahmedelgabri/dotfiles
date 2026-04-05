-- sidekick.nvim: AI assistant (lazy on keys)
-- TODO: Change keymaps for LSP to start with <leader>l to avoid conflicts

local sidekick_loaded = false
local function ensure_sidekick()
	if sidekick_loaded then
		return
	end
	sidekick_loaded = true
	vim.pack.add { 'https://github.com/folke/sidekick.nvim' }
	require('sidekick').setup {
		mux = { enabled = true },
	}
end

vim.keymap.set({ 'n', 't', 'i', 'x' }, '<LocalLeader>cc', function()
	ensure_sidekick()
	require('sidekick.cli').toggle()
end, { desc = 'Sidekick Toggle' })

vim.keymap.set('n', '<localleader>aa', function()
	ensure_sidekick()
	require('sidekick.cli').toggle()
end, { desc = 'Sidekick Toggle CLI' })

vim.keymap.set('n', '<localleader>as', function()
	ensure_sidekick()
	require('sidekick.cli').select { filter = { installed = true } }
end, { desc = 'Select CLI' })

vim.keymap.set({ 'x', 'n' }, '<localleader>at', function()
	ensure_sidekick()
	require('sidekick.cli').send { msg = '{this}' }
end, { desc = 'Send This' })

vim.keymap.set('n', '<localleader>af', function()
	ensure_sidekick()
	require('sidekick.cli').send { msg = '{file}' }
end, { desc = 'Send File' })

vim.keymap.set('x', '<localleader>av', function()
	ensure_sidekick()
	require('sidekick.cli').send { msg = '{selection}' }
end, { desc = 'Send Visual Selection' })

vim.keymap.set({ 'n', 'x' }, '<localleader>ap', function()
	ensure_sidekick()
	require('sidekick.cli').prompt()
end, { desc = 'Sidekick Select Prompt' })
