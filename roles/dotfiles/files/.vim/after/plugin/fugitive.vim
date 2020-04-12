if !exists('g:loaded_fugitive')
  finish
endif

" Open current file on github.com
nnoremap gb  :Gbrowse<cr>
vnoremap gb  :Gbrowse<cr>
nnoremap gs  :Gstatus<cr>
vnoremap gs  :Gstatus<cr>

augroup MY_FUGITIVE
  autocmd!
  " http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
  autocmd BufReadPost fugitive://* set bufhidden=delete
  autocmd User fugitive
        \ if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' |
        \   nnoremap <buffer> .. :edit %:h<CR> |
        \ endif
augroup END
