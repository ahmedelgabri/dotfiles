let g:projectionist_heuristics = {
      \   '*': {
      \     '*.js': {
      \       'alternate': [
      \         '{dirname}/{basename}.test.js',
      \         '{dirname}/{basename}.spec.js',
      \         '{dirname}/__tests__/{basename}.test.js',
      \         '{dirname}/__tests__/{basename}.spec.js',
      \       ],
      \       'type': 'source'
      \     },
      \     '*.test.js': {
      \       'alternate': [
      \         '{basename}.js',
      \         '{basename}/index.js'
      \        ],
      \       'type': 'test',
      \     },
      \     '**/__tests__/*.test.js': {
      \       'alternate': [
      \         '{basename}.js',
      \         '{basename}/index.js'
      \        ],
      \       'type': 'test'
      \     },
      \     '**/__tests__/*.spec.js': {
      \       'alternate': [
      \         '{basename}.js',
      \         '{basename}/index.js'
      \        ],
      \       'type': 'test'
      \     },
      \   }
      \ }
