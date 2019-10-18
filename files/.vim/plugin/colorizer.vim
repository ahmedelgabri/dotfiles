if exists(':ColorizerAttachToBuffer')
  finish
endif

if has('nvim') && exists('*luaeval')
" https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
lua << EOF
require 'colorizer'.setup ({
  '*';
  '!vim';
}, {
  mode = 'foreground';
  css  = true;
})
EOF
endif
