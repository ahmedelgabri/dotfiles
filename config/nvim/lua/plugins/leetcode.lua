return {
	{
		'https://github.com/kawre/leetcode.nvim',
		cmd = 'Leet',
		dependencies = {
			'https://github.com/ibhagwan/fzf-lua',
			'https://github.com/nvim-lua/plenary.nvim',
			'https://github.com/MunifTanjim/nui.nvim',
		},
		opts = function(_, opts)
			return vim.tbl_deep_extend('force', opts or {}, {
				lang = 'typescript',
			})
		end,
	},
}
