if !exists('g:loaded_fugitive')
  finish
endif

let g:fugitive_miro_domains=['code.devrtb.com']

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, miro#register('miro#get_url'))


" Open current file on github.com
nnoremap gb  :GBrowse<cr>
vnoremap gb  :GBrowse<cr>
nnoremap gs  :Git<cr>
vnoremap gs  :Git<cr>

augroup MY_FUGITIVE
  autocmd!
  " http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
  autocmd BufReadPost fugitive://* set bufhidden=delete
  autocmd User fugitive
        \ if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' |
        \   nnoremap <buffer> .. :edit %:h<CR> |
        \ endif
augroup END
