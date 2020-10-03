let g:waikiki_wiki_roots=[expand('$NOTES_DIR')]
" let g:waikiki_wiki_patterns = ['/wiki/', '\d+' ]
let g:waikiki_default_maps  = 1
" to account the '-' when creating a link from the world under cursor
" https://github.com/fcpg/vim-waikiki/issues/10
let g:waikiki_use_word_regex = 1
let g:waikiki_targetsdict_func = 'mywaikiki#TargetsDict'
let g:waikiki_lookup_order = ['raw', 'ext', 'subdir', 'myName']
let g:waikiki_create_type = 'myName'

" augroup Waikiki
"   au!
"   autocmd User setup call mywaikiki#SetupBuffer()
" augroup END
