if !has('nvim')
  finish
endif

silent! packadd nvim-lspconfig
silent! packadd nvim-treesitter

lua require 'init'
