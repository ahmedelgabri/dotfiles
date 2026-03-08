return {
	-- TODO: Change keymaps for LSP to start with <leader>l to avoid conflicts
	{
		'https://github.com/folke/sidekick.nvim',
		opts = {
			mux = { enabled = true },
		},
		keys = {
			{
				'<LocalLeader>cc',
				function()
					require('sidekick.cli').toggle()
				end,
				desc = 'Sidekick Toggle',
				mode = { 'n', 't', 'i', 'x' },
			},
			{
				'<localleader>aa',
				function()
					require('sidekick.cli').toggle()
				end,
				desc = 'Sidekick Toggle CLI',
			},
			{
				'<localleader>as',
				function()
					require('sidekick.cli').select { filter = { installed = true } }
				end,
				desc = 'Select CLI',
			},
			{
				'<localleader>at',
				function()
					require('sidekick.cli').send { msg = '{this}' }
				end,
				mode = { 'x', 'n' },
				desc = 'Send This',
			},
			{
				'<localleader>af',
				function()
					require('sidekick.cli').send { msg = '{file}' }
				end,
				desc = 'Send File',
			},
			{
				'<localleader>av',
				function()
					require('sidekick.cli').send { msg = '{selection}' }
				end,
				mode = { 'x' },
				desc = 'Send Visual Selection',
			},
			{
				'<localleader>ap',
				function()
					require('sidekick.cli').prompt()
				end,
				mode = { 'n', 'x' },
				desc = 'Sidekick Select Prompt',
			},
		},
	},
}
