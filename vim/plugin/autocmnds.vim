augroup ahmedAutoCmds
  autocmd!
  " Automatically make splits equal in size
  autocmd VimResized * wincmd =

  " Close preview buffer with q
  autocmd FileType preview,ag,qf nmap <buffer> <silent>  q :q<cr>

  " Disable paste mode on leaving insert mode.
  autocmd InsertLeave * set nopaste


  " https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/plugin/autocmds.vim#L27-L40
  if has('mksession')
    " Save/restore folds and cursor position.
    autocmd BufWritePost,BufLeave,WinLeave ?* if functions#should_mkview() | call functions#mkview() | endif
    if has('folding')
      autocmd BufWinEnter ?* if functions#should_mkview() | silent! loadview | execute 'silent! ' . line('.') . 'foldopen!' | endif
    else
      autocmd BufWinEnter ?* if functions#should_mkview() | silent! loadview | endif
    endif
  elseif has('folding')
    " Like the autocmd described in `:h last-position-jump` but we add `:foldopen!`.
    autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | execute 'silent! ' . line("'\"") . 'foldopen!' | endif
  else
    autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
  endif

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  " autocmd BufReadPost *
  "   \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
  "   \   exe "normal g`\"" |
  "   \ endif

  autocmd BufWritePre * call functions#Preserve("%s/\\s\\+$//e")
augroup END

" Automatically reload vimrc when it's saved
" augroup reload_vimrc
"     autocmd!
"     autocmd BufWritePost init.vim,vimrc.local,.vimrc nested so $MYVIMRC
" augroup END

aug omnicomplete
  autocmd!
  autocmd FileType css,scss,sass,stylus,less setl omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,htmldjango,jinja2 setl omnifunc=emmet#completeTag
  autocmd FileType javascript,javascript.jsx,jsx setl omnifunc=tern#Complete
  autocmd FileType python setl omnifunc=pythoncomplete#Complete
  autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
  autocmd FileType xml setl omnifunc=xmlcomplete#CompleteTags
aug END

