let s:keep_white_space = ['markdown']

augroup my_whitespace
  autocmd!
  " Ale is handling this currently
  " autocmd BufWritePre * if utils#should_strip_whitespace(s:keep_white_space) | call utils#Preserve("%s/\\s\\+$//e") | endif
augroup END

command! StripTrailingWhitespace call utils#Preserve("%s/\\s\\+$//e")
command! Reindent call utils#Preserve("normal gg=G")

nnoremap _= :Reindent<cr>
