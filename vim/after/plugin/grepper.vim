autocmd FileType GrepperSide
      \ silent execute 'keeppatterns v#'.b:grepper_side.'#>' | silent normal! n
