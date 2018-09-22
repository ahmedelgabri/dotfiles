if !exists('g:loaded_eunuch')
  finish
endif

" This command & mapping shadows the ones in mappings.vim
" if the plugin is available then use the plugin, if not fallback to the other one.

" Move is more flexiabile thatn Rename
" https://www.youtube.com/watch?v=Av2pDIY7nRY
map <leader>r :Move <C-R>=expand("%")<cr>

" Delete the current file and clear the buffer
command! Del Delete

" copied from https://github.com/duggiefresh/vim-easydir/blob/80f7fc2fd78d1c09cd6f8370012f20b58b5c6305/plugin/easydir.vim
augroup eunuch_easydir
  au!
  au BufWritePre,FileWritePre * call <SID>create_and_save_directory()
augroup END

function! <SID>create_and_save_directory()
  let s:directory = expand('<afile>:p:h')
  if s:directory !~# '^\(scp\|ftp\|dav\|fetch\|ftp\|http\|rcp\|rsync\|sftp\|file\):'
  \ && !isdirectory(s:directory)
    execute ':Mkdir! ' . s:directory
  endif
endfunction
