let g:flow#flowpath = g:current_flow_path
let g:cm_sources_override = {
      \ 'cm-tags': {'enable': 0},
      \ 'cm-bufkeyword' : {'abbreviation' : 'key'},
      \ 'cm-ultisnips' : {'abbreviation' : 'snip'},
      \ 'flow': {
      \     'scopes': ['javascript', 'javascript.jsx'],
      \     'abbreviation': 'flow'
      \   }
      \ }

au User CmSetup call cm#register_source({'name' : 'cm-css',
      \ 'priority': 9,
      \ 'scopes': ['css', 'scss', 'less', 'sass', 'styl'],
      \ 'scoping': 1,
      \ 'abbreviation': 'css',
      \ 'cm_refresh_patterns':['\w{2,}$',':\s+\w*$'],
      \ 'cm_refresh': {'omnifunc': 'csscomplete#CompleteCSS'},
      \ })
