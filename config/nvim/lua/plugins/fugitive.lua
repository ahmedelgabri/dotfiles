return {
	'https://github.com/tpope/vim-fugitive',
	dependencies = {
		{ 'https://github.com/tpope/vim-rhubarb' },
	},
	keys = {
		-- Open current file on github.com
		{ '<leader>gb', ':GBrowse<cr>' },
		{ '<leader>gb', ':GBrowse<cr>' },
		{ '<leader>gs', ':Git<cr>' },
		{ '<leader>gs', ':Git<cr>' },
	},
	config = function()
		local au = require '_.utils.au'

		vim.g.fugitive_miro_domains = { 'code.devrtb.com' }

		if vim.fn.exists 'g:fugitive_browse_handlers' == 0 then
			vim.g.fugitive_browse_handlers = {}
		end

		-- table.insert(
		--   vim.g.fugitive_browse_handlers,
		--   { vim.fn['miro#register'] 'miro#get_url' }
		-- )
		--
		vim.cmd [[call insert(g:fugitive_browse_handlers, function('miro#get_url'))]]

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
