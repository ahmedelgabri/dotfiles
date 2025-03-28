local utils = require '_.utils'

vim.opt.conceallevel = 2
vim.opt.concealcursor = 'c'

vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

utils.plaintext()
