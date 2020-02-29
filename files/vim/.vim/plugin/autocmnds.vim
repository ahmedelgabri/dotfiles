augroup MyAutoCmds
  autocmd!

  " Project specific override {{{
  autocmd BufRead,BufNewFile * call utils#sourceProjectConfig()

  if has('nvim')
    autocmd DirChanged * call utils#sourceProjectConfig()
  endif

  " Automatically make splits equal in size
  autocmd VimResized * wincmd =

  " Close preview buffer with q
  autocmd FileType * if utils#should_quit_on_q() | nmap <buffer> <silent> <expr>  q &diff ? ':qa!<cr>' : ':q<cr>' | endif

  " https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/plugin/autocmds.vim#L27-L40
  if has('mksession')
    " Save/restore folds and cursor position.
    autocmd BufWritePost,BufLeave,WinLeave ?* if utils#should_mkview() | call utils#mkview() | endif
    if has('folding')
      autocmd BufWinEnter ?* if utils#should_mkview() | silent! loadview | execute 'silent! ' . line('.') . 'foldopen!' | endif
    else
      autocmd BufWinEnter ?* if utils#should_mkview() | silent! loadview | endif
    endif
  elseif has('folding')
    " Like the autocmd described in `:h last-position-jump` but we add `:foldopen!`.
    autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | execute 'silent! ' . line("'\"") . 'foldopen!' | endif
  else
    autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
  endif

  " taken from https://github.com/jeffkreeftmeijer/vim-numbertoggle/blob/cfaecb9e22b45373bb4940010ce63a89073f6d8b/plugin/number_toggle.vim
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu | set nornu | endif

  " See https://github.com/neovim/neovim/issues/7994
  autocmd InsertLeave * set nopaste

  autocmd FileType gitcommit,gina-status,todo,qf setlocal cursorline

  autocmd FileType lisp,scheme,clojure packadd rainbow_parentheses.vim | packadd vim-sexp | RainbowParentheses

  autocmd BufWritePre,FileWritePre * call utils#create_directories()
  autocmd BufEnter,BufWinEnter,BufRead,BufNewFile bookmarks.{md,txt} hi! link mkdLink Normal | set concealcursor-=n

  if executable('direnv')
    autocmd BufWritePost .envrc silent !direnv allow %
  endif
augroup END
