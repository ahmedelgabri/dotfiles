" Load all lua code

if has('nvim') && exists('*luaeval')
  lua require 'init'
endif
