if !exists(':LanguageClientStart')
  finish
endif

let g:LanguageClient_autoStart = 1
let g:LanguageClient_serverCommands = {
      \ 'javascript': ['javascript-typescript-stdio'],
      \ 'javascript.jsx': ['javascript-typescript-stdio'],
      \ 'html': ['html-languageserver', '--stdio'],
      \ 'html.twig': ['html-languageserver', '--stdio'],
      \ 'htmldjango.twig': ['html-languageserver', '--stdio'],
      \ 'css': ['css-languageserver', '--stdio'],
      \ 'scss': ['css-languageserver', '--stdio'],
      \ 'reason': ['ocaml-language-server', '--stdio'],
      \ 'ocaml': ['ocaml-language-server', '--stdio'],
      \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
      \ }

let g:LanguageClient_diagnosticsDisplay = {
      \   1: {
      \       'name': 'Error',
      \       'texthl': 'ALEError',
      \       'signText': '●',
      \       'signTexthl': 'ALEErrorSign',
      \   },
      \   2: {
      \       'name': 'Warning',
      \       'texthl': 'ALEWarning',
      \       'signText': '●',
      \       'signTexthl': 'ALEWarningSign',
      \   },
      \   3: {
      \       'name': 'Information',
      \       'texthl': 'ALEInfo',
      \       'signText': '●',
      \       'signTexthl': 'ALEInfoSign',
      \   },
      \   4: {
      \       'name': 'Hint',
      \       'texthl': 'ALEInfo',
      \       'signText': '●',
      \       'signTexthl': 'ALEInfoSign',
      \   },
      \ }

