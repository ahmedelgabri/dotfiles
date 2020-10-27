if !has('nvim-0.5.0')
  finish
endif

silent! packadd nvim-lspconfig
silent! packadd nvim-treesitter

lua require 'init'
