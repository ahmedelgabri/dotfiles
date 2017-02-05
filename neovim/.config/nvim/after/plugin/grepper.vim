xmap gs <plug>(GrepperOperator)
vmap gs <Plug>(GrepperOperator)

command! Todo :Grepper
      \ -side
      \ -noprompt
      \ -tool git
      \ -grepprg git grep -nIi '\@\?\(TODO\|FIXME\)'

autocmd FileType GrepperSide
      \  silent execute 'keeppatterns v#'.b:grepper_side.'#>'
      \| silent normal! ggn
      \| setl wrap
