command! Todo :Grepper
      \ -side
      \ -noprompt
      \ -tool git
      \ -grepprg git grep -nIi '(TODO\|FIXME\|NOTE)'

augroup MyGrepper
  autocmd!
  autocmd FileType GrepperSide
      \  silent execute 'keeppatterns v#'.b:grepper_side.'#>'
      \| silent normal! ggn
      \| setl wrap
augroup END

xmap gs <plug>(GrepperOperator)
vmap gs <Plug>(GrepperOperator)
" https://github.com/mhinz/vim-grepper/issues/180#issuecomment-433403860
nnoremap \ :silent! packadd vim-grepper<cr> \| :Grepper -side -noprompt -tool rg -grepprg rg --vimgrep<space>
" nnoremap \\ :Grepper -side -tool git -query<SPACE>
