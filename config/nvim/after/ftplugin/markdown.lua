local utils = require '_.utils'

vim.wo.conceallevel = 2
vim.wo.concealcursor = 'c'

vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Workaround for: https://github.com/neovim/neovim/issues/33926
vim.wo.foldminlines = 1

utils.plaintext()
