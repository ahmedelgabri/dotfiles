" This dance to get around vim-polyglot issue with vim-go
" https://github.com/sheerun/vim-polyglot/issues/309
" https://github.com/sheerun/vim-polyglot/issues/357

" only do these things once
if exists('g:polyglot_disabled') && index(get(g:, 'polyglot_disabled'), 'go') < 0
  let g:polyglot_disabled += ['go']
  packadd go.vim
endif
