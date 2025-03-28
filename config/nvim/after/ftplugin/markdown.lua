local utils = require '_.utils'

vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = 'c'

vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

utils.plaintext()
