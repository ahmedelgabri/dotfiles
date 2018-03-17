augroup FT_JSON
  au!
  au BufRead,BufNewFile .{babel,eslint,stylelint,jshint,prettier}rc,.tern-* setl ft=json
augroup END

