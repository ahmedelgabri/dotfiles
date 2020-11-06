if !has('nvim-0.5.0')
  finish
endif

silent! packadd nvim-lspconfig

lua require 'init'
