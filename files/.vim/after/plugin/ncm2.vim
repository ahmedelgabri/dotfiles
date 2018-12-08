if get(g:,'ncm2_loaded','0')
  finish
endif

let g:ncm2#popup_delay = 20
let g:ncm2#matcher = 'substrfuzzy'
set shortmess+=c

" let g:cm_sources_override = {
"       \ 'cm-tags': {'enable': 0},
"       \ 'cm-bufkeyword' : {'abbreviation' : 'buf'},
"       \ 'cm-ultisnips' : {'abbreviation' : 'snip'},
"       \ 'flow': {
"       \     'scopes': ['javascript', 'javascript.jsx'],
"       \     'abbreviation': 'flow'
"       \   }
"       \ }
