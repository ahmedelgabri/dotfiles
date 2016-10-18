" Automatically make splits equal in size
autocmd VimResized * wincmd =

" Close preview buffer with q
autocmd FileType preview,ag,netrw,qf nmap <buffer> <silent>  q :q<cr>

augroup vimrcEx
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  autocmd BufWritePre * call Preserve("%s/\\s\\+$//e")
augroup END

" Automatically reload vimrc when it's saved
" augroup reload_vimrc
"     autocmd!
"     autocmd BufWritePost init.vim,vimrc.local,.vimrc nested so $MYVIMRC
" augroup END

" aug omnicomplete
"   autocmd!
"   autocmd FileType css,scss,sass,stylus,less setl omnifunc=csscomplete#CompleteCSS
"   autocmd FileType html,htmldjango,jinja setl omnifunc=emmet#completeTag
"   autocmd FileType javascript,javascript.jsx,jsx setl omnifunc=tern#Complete
"   autocmd FileType python setl omnifunc=pythoncomplete#Complete
"   autocmd FileType xml setl omnifunc=xmlcomplete#CompleteTags
" aug END
