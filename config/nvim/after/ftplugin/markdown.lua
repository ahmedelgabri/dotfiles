local utils = require '_.utils'

vim.wo.conceallevel = 2
vim.wo.concealcursor = 'c'

vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

utils.plaintext()
