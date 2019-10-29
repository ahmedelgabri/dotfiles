" This dance to get around vim-polyglot issue with vim-go
" https://github.com/sheerun/vim-polyglot/issues/309
" https://github.com/sheerun/vim-polyglot/issues/357

" this doesn't seem to have an effect, but I'll keep it anyway
if index(get(g:, 'polyglot_disabled'), 'go') < 0
  let g:polyglot_disabled += ['go']
endif

packadd go.vim
