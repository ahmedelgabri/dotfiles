if !has('nvim')
  " Must explicitly load this before vim-sensible, becasue vim-sensible will
  " load match-it which we don't want. order is important.
  " https://github.com/andymass/vim-matchup#matchit
  silent! packadd vim-matchup
  silent! packadd vim-sensible
  if !has('nvim') " For vim
    if exists('&belloff')
      " never ring the bell for any reason
      set belloff=all
    endif
    if has('showcmd')
      " extra info at end of command line
      set showcmd
    endif
    if &term =~# '^tmux'
      let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
      let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    endif
  endif
endif
