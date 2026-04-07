local au = require '_.utils.au'

Pack.add {
	'https://github.com/tpope/vim-rhubarb',
	'https://github.com/tpope/vim-fugitive',
	'https://github.com/Tronikelis/conflict-marker.nvim',
	{ src = 'https://github.com/jez/vim-github-hub', load = false },
	{ src = 'https://github.com/MunifTanjim/nui.nvim', load = false },
	{ src = 'https://github.com/esmuellert/codediff.nvim', load = false },
}

au.autocmd {
	event = 'FileType',
	pattern = { 'markdown.ghpull', 'markdown.ghissue', 'markdown.ghrelease' },
	callback = function()
		Pack.load 'vim-github-hub'
	end,
}

Pack.cmd('CodeDiff', function()
	Pack.load { 'nui.nvim', 'codediff.nvim' }

	require('codediff').setup {
		explorer = {
			view_mode = 'tree',
		},
	}
end)

vim.keymap.set({ 'n', 'v' }, '<leader>gb', ':GBrowse<cr>', {
	desc = '[G]it [B]rowse file',
})
vim.keymap.set({ 'n', 'v' }, '<leader>gs', ':Git<cr>', {
	desc = '[G]it [S]tatus',
})

local fugitive_group = vim.api.nvim_create_augroup('__my_fugitive__', {
	clear = true,
})

-- http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
vim.api.nvim_create_autocmd('BufReadPost', {
	group = fugitive_group,
	pattern = 'fugitive://*',
	callback = function()
		vim.bo.bufhidden = 'delete'
	end,
})

vim.api.nvim_create_autocmd('User', {
	group = fugitive_group,
	pattern = 'fugitive',
	command = [[if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' | nnoremap <buffer> .. :edit %:h<CR> | endif]],
})

require('conflict-marker').setup {
	on_attach = function(conflict)
		local map = function(key, fn)
			vim.keymap.set('n', key, fn, { buf = conflict.bufnr })
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
}
