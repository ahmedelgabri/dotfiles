local utils = require '_.utils'

return {
	{
		'https://github.com/jez/vim-github-hub',
		-- Hub filetypes, also chceck filetypes.lua
		ft = { 'markdown.ghpull', 'markdown.ghissue', 'markdown.ghrelease' },
	},
	{
		'https://github.com/akinsho/git-conflict.nvim',
		event = { 'BufReadPre' },
		opts = {},
	},
	{
		'https://github.com/sindrets/diffview.nvim',
		dependencies = { { 'https://github.com/nvim-lua/plenary.nvim' } },
		cmd = { 'DiffviewOpen' },
		opts = {},
	},
	{
		'https://github.com/tpope/vim-fugitive',
		event = utils.LazyFile,
		dependencies = {
			{ 'https://github.com/tpope/vim-rhubarb' },
		},
		keys = {
			-- Open current file on github.com
			{
				'<leader>gb',
				':GBrowse<cr>',
				mode = { 'n', 'v' },
				desc = '[G]it [B]rowse file',
			},
			{
				'<leader>gs',
				':Git<cr>',
				mode = { 'n', 'v' },
				desc = '[G]it [S]tatus',
			},
		},
		init = function()
			local au = require '_.utils.au'

			au.augroup('__my_fugitive__', {
				-- http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
				{
					event = 'BufReadPost',
					pattern = 'fugitive://*',
					callback = function()
						vim.opt.bufhidden = 'delete'
					end,
				},
				{
					event = 'User',
					pattern = 'fugitive',
					command = [[if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' | nnoremap <buffer> .. :edit %:h<CR> | endif]],
				},
			})
		end,
	},
}
