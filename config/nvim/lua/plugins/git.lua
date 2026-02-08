return {
	{
		'https://github.com/jez/vim-github-hub',
		-- Hub filetypes, also chceck filetypes.lua
		ft = { 'markdown.ghpull', 'markdown.ghissue', 'markdown.ghrelease' },
	},
	{
		'https://github.com/Tronikelis/conflict-marker.nvim',
		opts = {
			on_attach = function(conflict)
				local map = function(key, fn)
					vim.keymap.set('n', key, fn, { buffer = conflict.bufnr })
				end

				map('co', function()
					conflict:choose_ours()
				end)
				map('ct', function()
					conflict:choose_theirs()
				end)
				map('cb', function()
					conflict:choose_both()
				end)
				map('cn', function()
					conflict:choose_none()
				end)
			end,
		},
	},
	{
		'https://github.com/tpope/vim-fugitive',
		lazy = false, -- we need it for the statusline branch info
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
						vim.bo.bufhidden = 'delete'
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
	{
		'https://github.com/esmuellert/codediff.nvim',
		dependencies = { 'https://github.com/MunifTanjim/nui.nvim' },
		cmd = { 'CodeDiff' },
		opts = {
			explorer = {
				view_mode = 'tree',
			},
		},
	},
}
