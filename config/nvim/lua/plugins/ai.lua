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

local function with_sidekick_cli(fn)
	if not ensure_sidekick() then
		return
	end

	fn(require 'sidekick.cli')
end

for _, mapping in ipairs {
	{
		modes = { 'n', 't', 'i', 'x' },
		lhs = '<LocalLeader>cc',
		desc = 'Sidekick Toggle',
		callback = function(cli)
			cli.toggle()
		end,
	},
	{
		modes = 'n',
		lhs = '<localleader>aa',
		desc = 'Sidekick Toggle CLI',
		callback = function(cli)
			cli.toggle()
		end,
	},
	{
		modes = 'n',
		lhs = '<localleader>as',
		desc = 'Select CLI',
		callback = function(cli)
			cli.select { filter = { installed = true } }
		end,
	},
	{
		modes = { 'x', 'n' },
		lhs = '<localleader>at',
		desc = 'Send This',
		callback = function(cli)
			cli.send { msg = '{this}' }
		end,
	},
	{
		modes = 'n',
		lhs = '<localleader>af',
		desc = 'Send File',
		callback = function(cli)
			cli.send { msg = '{file}' }
		end,
	},
	{
		modes = 'x',
		lhs = '<localleader>av',
		desc = 'Send Visual Selection',
		callback = function(cli)
			cli.send { msg = '{selection}' }
		end,
	},
	{
		modes = { 'n', 'x' },
		lhs = '<localleader>ap',
		desc = 'Sidekick Select Prompt',
		callback = function(cli)
			cli.prompt()
		end,
	},
} do
	vim.keymap.set(mapping.modes, mapping.lhs, function()
		with_sidekick_cli(mapping.callback)
	end, { desc = mapping.desc })
end
