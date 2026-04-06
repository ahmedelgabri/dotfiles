-- leetcode.nvim: lazy on cmd and argv
local pack = require 'plugins.pack'

local leet_arg = 'leet'
local is_leet = leet_arg == vim.fn.argv()[1]

local function ensure_leetcode()
	pcall(vim.api.nvim_del_user_command, 'Leet')
	return pack.setup('leetcode.nvim', { 'nui.nvim', 'leetcode.nvim' }, function()
		local map = vim.api.nvim_set_keymap

		map(
			'n',
			'<localleader>lc',
			'<Cmd>Leet console<Cr>',
			{ desc = 'Leet: Console' }
		)
		map('n', '<localleader>lr', '<Cmd>Leet run<Cr>', { desc = 'Leet: Run' })
		map('n', '<localleader>lt', '<Cmd>Leet test<Cr>', { desc = 'Leet: Test' })
		map(
			'n',
			'<localleader>ls',
			'<Cmd>Leet submit<Cr>',
			{ desc = 'Leet: Submit' }
		)
		map(
			'n',
			'<localleader>ll',
			'<Cmd>Leet list<Cr>',
			{ desc = 'Leet: Select question (all)' }
		)
		map(
			'n',
			'<localleader>lL',
			'<Cmd>Leet list status=notac<Cr>',
			{ desc = 'Leet: Select question (in progress)' }
		)

		---@diagnostic disable-next-line: missing-fields, param-type-mismatch
		require('leetcode').setup {
			arg = leet_arg,
			lang = 'typescript',
			storage = {
				home = (vim.env.PROJECTS or vim.fn.stdpath 'data')
					.. '/assignments/_prep/'
					.. os.date '%Y'
					.. '/',
				cache = vim.fn.stdpath 'cache' .. '/leetcode/',
			},
		}
	end)
end

-- Load immediately if started with 'leet' argument
if is_leet then
	ensure_leetcode()
else
	-- Also lazy load on :Leet command
	vim.api.nvim_create_user_command('Leet', function(opts)
		if not ensure_leetcode() then
			return
		end
		pack.run_command('Leet', opts)
	end, { nargs = '*', bang = true })
end
