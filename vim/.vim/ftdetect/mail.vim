augroup FT_MAIL
  au!
  " https://github.com/vim/vim/blob/d9bc8a801aeaffa77d4094d43bf97f0ced3db92b/runtime/filetype.vim#L1158-L1159
  au BufRead,BufNewFile neomutt{ng,}-*-\w\+,neomutt[[:alnum:]_-]\\\{6\} set ft=mail
augroup END

