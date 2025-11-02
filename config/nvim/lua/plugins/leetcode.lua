local leet_arg = 'leet'

return {
	{
		'https://github.com/kawre/leetcode.nvim',
		lazy = leet_arg ~= vim.fn.argv()[1],
		cmd = 'Leet',
		dependencies = {
			'https://github.com/ibhagwan/fzf-lua',
			'https://github.com/nvim-lua/plenary.nvim',
			'https://github.com/MunifTanjim/nui.nvim',
		},
		config = function()
			local map = vim.api.nvim_set_keymap

			map(
				'n',
				'<localleader>lc',
				'<Cmd>Leet console<Cr>',
				{ desc = 'Leet: Console' }
			)
			map('n', '<localleader>lr', '<Cmd>Leet run<Cr>', { desc = 'Leet: Run' })
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

			require('leetcode').setup {
				arg = leet_arg,
				lang = 'typescript',
				storage = {
					home = (vim.env.PROJECTS or vim.fn.stdpath 'data') .. '/leetcode',
					cache = vim.fn.stdpath 'cache' .. '/leetcode',
				},
			}
		end,
	},
}
