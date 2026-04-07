Pack.add({
	'https://github.com/nvim-lua/plenary.nvim',
	{ src = 'https://github.com/MunifTanjim/nui.nvim' },
	{ src = 'https://github.com/kawre/leetcode.nvim' },
}, { load = false })

local leet_arg = 'leet'
local is_leet = leet_arg == vim.fn.argv()[1]
Pack.cmd('Leet', function()
	Pack.load { 'plenary.nvim', 'nui.nvim', 'leetcode.nvim' }

	local map = vim.keymap.set

	map('n', '<localleader>lc', '<Cmd>Leet console<Cr>', {
		desc = 'Leet: Console',
	})
	map('n', '<localleader>lr', '<Cmd>Leet run<Cr>', {
		desc = 'Leet: Run',
	})
	map('n', '<localleader>lt', '<Cmd>Leet test<Cr>', {
		desc = 'Leet: Test',
	})
	map('n', '<localleader>ls', '<Cmd>Leet submit<Cr>', {
		desc = 'Leet: Submit',
	})
	map('n', '<localleader>ll', '<Cmd>Leet list<Cr>', {
		desc = 'Leet: Select question (all)',
	})
	map('n', '<localleader>lL', '<Cmd>Leet list status=notac<Cr>', {
		desc = 'Leet: Select question (in progress)',
	})

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

if is_leet then
	vim.schedule(function()
		vim.cmd.Leet()
	end)
end
