command! Todo :Grepper
      \ -side
      \ -noprompt
      \ -tool git
      \ -grepprg git grep -nIi '\@\?\(TODO\|FIXME\)'

autocmd FileType GrepperSide
      \  silent execute 'keeppatterns v#'.b:grepper_side.'#>'
      \| silent normal! ggn
      \| setl wrap

xmap gs <plug>(GrepperOperator)
vmap gs <Plug>(GrepperOperator)
nnoremap \ :Grepper -side -tool rg -query --hidden<SPACE>
" nnoremap \\ :Grepper -side -tool git -query<SPACE>
