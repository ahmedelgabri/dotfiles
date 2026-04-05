-- leetcode.nvim: lazy on cmd and argv
local leet_arg = 'leet'
local is_leet = leet_arg == vim.fn.argv()[1]

local leetcode_loaded = false
local function ensure_leetcode()
	if leetcode_loaded then
		return
	end
	leetcode_loaded = true
	vim.pack.add {
		'https://github.com/nvim-lua/plenary.nvim',
		'https://github.com/MunifTanjim/nui.nvim',
		'https://github.com/ibhagwan/fzf-lua',
		'https://github.com/kawre/leetcode.nvim',
	}

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
end

-- Load immediately if started with 'leet' argument
if is_leet then
	ensure_leetcode()
end

-- Also lazy load on :Leet command
vim.api.nvim_create_user_command('Leet', function(opts)
	pcall(vim.api.nvim_del_user_command, 'Leet')
	ensure_leetcode()
	vim.cmd('Leet ' .. (opts.args or ''))
end, { nargs = '*' })
