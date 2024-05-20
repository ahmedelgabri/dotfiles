return {
	'https://github.com/tpope/vim-fugitive',
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
		{ '<leader>gs', ':Git<cr>', mode = { 'n', 'v' }, desc = '[G]it [S]tatus' },
	},
	cmd = { 'Git' },
	config = function()
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
}
