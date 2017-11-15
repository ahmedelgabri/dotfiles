if executable('jq')
  setlocal formatprg=jq\ .
else
  setlocal formatprg=python\ -m\ json.tool
endif
au BufRead,BufNewFile .{babel,eslint,stylelint,jshint,prettier}rc,.tern-*,*.json set ft=json

