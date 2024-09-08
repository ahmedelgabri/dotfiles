return {
	-- Needs gomodifytags
	'https://github.com/devkvlt/go-tags.nvim',
	ft = 'go',
	dependacies = {
		'https://github.com/nvim-treesitter/nvim-treesitter',
	},
	config = function()
		require('go-tags').setup {
			commands = {
				['GoTagsAddJSON'] = { '-add-tags', 'json' },
				['GoTagsRemoveJSON'] = { '-remove-tags', 'json' },
			},
		}
	end,
}
