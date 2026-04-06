-- Git plugins
local au = require '_.utils.au'
local pack = require 'plugins.pack'

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
	callback = function()
		pack.load 'vim-github-hub'
	end,
})

-- codediff.nvim: lazy on cmd
do
	local function ensure_codediff()
		return pack.setup(
			'codediff.nvim',
			{ 'nui.nvim', 'codediff.nvim' },
			function()
				require('codediff').setup {
					explorer = {
						view_mode = 'tree',
					},
				}
			end
		)
	end

	pack.lazy_cmd('CodeDiff', ensure_codediff)
end
