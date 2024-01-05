vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
-- Next lines are taken from here https://github.com/h3xx/dotfiles/blob/master/vim/.vimrc#L543-L582
-- horizontally split the window when opening a file via <cr>
vim.g.netrw_browse_split = 4
vim.g.netrw_sizestyle = 'H'
-- split files below, right
vim.g.netrw_alto = 1
vim.g.netrw_altv = 1
vim.g.netrw_hide = 1

-- bug workaround:
-- set bufhidden=wipe in netrw windows to circumvent a bug where vim won't let
-- you quit (!!!) if a netrw buffer doesn't like it
-- also buftype should prevent you from :w
-- (reproduce bug by opening netrw, :e ., :q)
vim.g.netrw_bufsettings = 'noma nomod nonu nobl nowrap ro' -- default
vim.g.netrw_bufsettings = vim.g.netrw_bufsettings
	.. ' buftype=nofile bufhidden=wipe'

-- :NvimTreeFindFile like functionality
-- https://superuser.com/a/1814266
vim.keymap.set('n', '--', function()
	local relative_path = vim.fn.expand '%:h'
	local startPos, endPos = string.find(relative_path, '/')

	if startPos == 1 then
		relative_path = '.'
	end

	vim.cmd [[:let @/=expand("%:t")]]
	-- 20 is the size of the split
	-- ! is to open it on the right side
	vim.cmd('20Lexplore! ' .. relative_path)

	if startPos > 1 then
		while startPos ~= nil do
			startPos, endPos = string.find(relative_path, '/', endPos + 1)
			vim.fn['netrw#Call']('NetrwBrowseUpDir', 1)
		end
		vim.fn['netrw#Call']('NetrwBrowseUpDir', 1)
	end

	vim.cmd.normal 'n<CR>zz'
end)
