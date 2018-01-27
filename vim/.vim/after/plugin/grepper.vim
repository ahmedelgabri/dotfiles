command! Todo :Grepper
      \ -side
      \ -noprompt
      \ -tool git
      \ -grepprg git grep -nIi '\@\?\(TODO\|FIXME\)'

augroup MyGrepper
  autocmd!
  autocmd FileType GrepperSide
      \  silent execute 'keeppatterns v#'.b:grepper_side.'#>'
      \| silent normal! ggn
      \| setl wrap
augroup END

xmap gs <plug>(GrepperOperator)
vmap gs <Plug>(GrepperOperator)
nnoremap \ :packadd vim-grepper<cr> <BAR> :Grepper -side -tool rg -query --hidden<SPACE>
" nnoremap \\ :Grepper -side -tool git -query<SPACE>
