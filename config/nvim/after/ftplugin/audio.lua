vim.ui.open(vim.fn.expand '%:p')
vim.cmd [[buffer# | bdelete# | redraw! | syntax on]]
