-- Git plugins
local au = require '_.utils.au'

-- Eager: fugitive + rhubarb (needed for statusline branch info)
vim.pack.add {
	'https://github.com/tpope/vim-rhubarb',
	'https://github.com/tpope/vim-fugitive',
	'https://github.com/Tronikelis/conflict-marker.nvim',
}

-- fugitive keymaps
vim.keymap.set({ 'n', 'v' }, '<leader>gb', ':GBrowse<cr>', {
	desc = '[G]it [B]rowse file',
})
vim.keymap.set({ 'n', 'v' }, '<leader>gs', ':Git<cr>', {
	desc = '[G]it [S]tatus',
})

-- fugitive init autocmds
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

-- conflict-marker setup
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

-- vim-github-hub: lazy on filetype
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'markdown.ghpull', 'markdown.ghissue', 'markdown.ghrelease' },
	once = true,
	callback = function()
		vim.pack.add { 'https://github.com/jez/vim-github-hub' }
	end,
})

-- codediff.nvim: lazy on cmd
do
	local codediff_loaded = false
	vim.api.nvim_create_user_command('CodeDiff', function(opts)
		if not codediff_loaded then
			codediff_loaded = true
			pcall(vim.api.nvim_del_user_command, 'CodeDiff')
			vim.pack.add {
				'https://github.com/MunifTanjim/nui.nvim',
				'https://github.com/esmuellert/codediff.nvim',
			}
			require('codediff').setup {
				explorer = {
					view_mode = 'tree',
				},
			}
		end
		vim.cmd('CodeDiff ' .. (opts.args or ''))
	end, { nargs = '*' })
end
