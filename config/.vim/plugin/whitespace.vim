command! Reindent call utils#Preserve("normal gg=G")

nnoremap _= :Reindent<cr>


let s:keep_white_space = ['markdown', 'diff']

augroup my_whitespace
  autocmd!
  autocmd BufWritePre * if utils#should_strip_whitespace(s:keep_white_space) | call utils#Preserve("%s/\\s\\+$//e") | endif
  " autocmd BufWritePre * v/\_s*\S/d
  " autocmd BufWritePre * call utils#Preserve("%s#\($\n\s*\)\+\%$##")
augroup END
