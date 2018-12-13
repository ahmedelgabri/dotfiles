augroup MyAutoCmds
  autocmd!

  " Project specific override {{{
  autocmd BufRead,BufNewFile * call functions#sourceProjectConfig()

  if has('nvim')
    autocmd DirChanged * call functions#sourceProjectConfig()
  endif

  " Automatically make splits equal in size
  autocmd VimResized * wincmd =

  " Close preview buffer with q
  autocmd FileType * if functions#should_quit_on_q() | nmap <buffer> <silent>  q :q<cr> | endif

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

  " autocmd BufWritePre * if functions#should_strip_whitespace() | call functions#Preserve("%s/\\s\\+$//e") | endif

  " taken from https://github.com/jeffkreeftmeijer/vim-numbertoggle/blob/cfaecb9e22b45373bb4940010ce63a89073f6d8b/plugin/number_toggle.vim
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu | set nornu | endif

  " See https://github.com/neovim/neovim/issues/7994
  autocmd InsertLeave * set nopaste

  autocmd FileType gitcommit,gina-status,todo,qf setlocal cursorline

  autocmd FileType lisp,clojure,scheme RainbowParentheses

  autocmd BufWritePre,FileWritePre * call functions#create_directories()
augroup END
