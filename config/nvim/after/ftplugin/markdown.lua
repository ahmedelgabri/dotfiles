local utils = require '_.utils'

vim.opt.conceallevel = 2
vim.opt.concealcursor = 'c'

local has_treesitter = pcall(require, 'nvim-treesitter')
if has_treesitter then
	vim.opt_local.foldmethod = 'expr'
	vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
end

utils.plaintext()
