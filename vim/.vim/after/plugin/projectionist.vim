let g:projectionist_heuristics = {
      \   '*': {
      \     '*.js': {
      \       'alternate': [
      \         '{dirname}/{basename}.test.js',
      \         '{dirname}/{basename}.spec.js',
      \         '{dirname}/{dirname}.test.js',
      \         '{dirname}/{dirname}.spec.js',
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
      \     '*.spec.js': {
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
      \     'src/*.re': {
      \       'alternate': [
      \         '__tests__/{}_test.re',
      \         'src/{}_test.re',
      \         'src/{}.rei'
      \       ],
      \       'type': 'source'
      \     },
      \     'src/*.rei': {
      \       'alternate': [
      \         'src/{}.re',
      \         '__tests__/{}_test.re',
      \         'src/{}_test.re',
      \       ],
      \       'type': 'header'
      \     },
      \     '__tests__/*_test.re': {
      \       'alternate': [
      \         'src/{}.rei',
      \         'src/{}.re',
      \       ],
      \       'type': 'test'
      \     }
      \   }
      \ }
