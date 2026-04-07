-- sidekick.nvim: AI assistant (lazy on keys)
-- TODO: Change keymaps for LSP to start with <leader>l to avoid conflicts

Pack.add({
	{ src = 'https://github.com/folke/sidekick.nvim' },
}, { load = false })

Pack.keys({
	{
		mode = { 'n', 't', 'i', 'x' },
		lhs = '<LocalLeader>cc',
		opts = { desc = 'Sidekick Toggle' },
		rhs = function()
			require('sidekick.cli').toggle()
		end,
	},
	{
		mode = 'n',
		lhs = '<localleader>aa',
		opts = { desc = 'Sidekick Toggle CLI' },
		rhs = function()
			require('sidekick.cli').toggle()
		end,
	},
	{
		mode = 'n',
		lhs = '<localleader>as',
		opts = { desc = 'Select CLI' },
		rhs = function()
			require('sidekick.cli').select { filter = { installed = true } }
		end,
	},
	{
		mode = { 'x', 'n' },
		lhs = '<localleader>at',
		opts = { desc = 'Send This' },
		rhs = function()
			require('sidekick.cli').send { msg = '{this}' }
		end,
	},
	{
		mode = 'n',
		lhs = '<localleader>af',
		opts = { desc = 'Send File' },
		rhs = function()
			require('sidekick.cli').send { msg = '{file}' }
		end,
	},
	{
		mode = 'x',
		lhs = '<localleader>av',
		opts = { desc = 'Send Visual Selection' },
		rhs = function()
			require('sidekick.cli').send { msg = '{selection}' }
		end,
	},
	{
		mode = { 'n', 'x' },
		lhs = '<localleader>ap',
		opts = { desc = 'Sidekick Select Prompt' },
		rhs = function()
			require('sidekick.cli').prompt()
		end,
	},
}, function()
	Pack.load 'sidekick.nvim'
	require('sidekick').setup {
		mux = { enabled = true },
	}
end)
