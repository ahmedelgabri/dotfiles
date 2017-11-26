let g:cm_matcher = {'module': 'cm_matchers.substr_matcher', 'case': 'smartcase'}
let g:cm_sources_override = {
      \ 'cm-tags': {'enable': 0},
      \ 'cm-bufkeyword' : {'abbreviation' : 'buf'},
      \ 'cm-ultisnips' : {'abbreviation' : 'snip'},
      \ 'flow': {
      \     'scopes': ['javascript', 'javascript.jsx'],
      \     'abbreviation': 'flow'
      \   }
      \ }
