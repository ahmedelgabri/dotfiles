local utils = require '_.utils'

vim.wo.conceallevel = 2
vim.wo.concealcursor = 'c'

vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Workaround for: https://github.com/neovim/neovim/issues/33926
vim.wo.foldminlines = 1

utils.plaintext()

local function preview_markdown()
	local file = vim.fn.expand '%'
	local on_exit_cb = function(out)
		print('Markdown preview process exited with code:', out.code)
	end
	local process = vim.system(
		-- assuming that the extension were installed using gh
		-- the reason we are not using `gh gfm-preview` instead is because this
		-- can cause an issue where the gh process is killed but not the
		-- gh-gfm-preview, since the kill signal will not reach the child process
		{
			vim.fn.expand 'gh-gfm-preview',
			file,
		},
		on_exit_cb
	)

	vim.api.nvim_create_autocmd({ 'BufUnload', 'BufDelete' }, {
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			process:kill 'sigterm'
			-- timeout (in ms), will call SIGKILL upon timeout
			process:wait(500)
		end,
	})
end

-- create a shortcut only in Markdown files, mapped to `<Leader>P`
vim.api.nvim_create_autocmd({ 'FileType' }, {
	pattern = { 'markdown' },
	callback = function()
		vim.keymap.set('n', '<Leader>p', preview_markdown, {
			desc = 'Markdown preview',
			buffer = true,
			desc = '[P]review Markdown',
		})
	end,
})
