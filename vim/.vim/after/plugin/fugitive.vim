if !exists('g:loaded_fugitive')
  finish
endif

" Open current file on github.com
nnoremap gb  :Gbrowse<cr>
vnoremap gb  :Gbrowse<cr>
nnoremap gs  :Gstatus<cr>
vnoremap gs  :Gstatus<cr>

