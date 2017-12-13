if !exists(':LanguageClientStart')
  finish
endif

let g:LanguageClient_autoStart = 1
let g:LanguageClient_diagnosticsEnable = 0
let g:LanguageClient_serverCommands = {}

if executable('javascript-typescript-stdio')
  let g:LanguageClient_serverCommands.javascript = ['javascript-typescript-stdio']
  let g:LanguageClient_serverCommands['javascript.jsx'] = ['javascript-typescript-stdio']
endif
if executable('html-languageserver')
  let g:LanguageClient_serverCommands.html = ['html-languageserver', '--stdio']
  let g:LanguageClient_serverCommands['html.twig'] = ['html-languageserver', '--stdio']
  let g:LanguageClient_serverCommands['htmldjango.twig'] = ['html-languageserver', '--stdio']
endif
if executable('css-languageserver')
  let g:LanguageClient_serverCommands.css = ['css-languageserver', '--stdio']
  let g:LanguageClient_serverCommands.scss = ['css-languageserver', '--stdio']
endif
if executable('ocaml-language-server')
  let g:LanguageClient_serverCommands.reason = ['ocaml-language-server', '--stdio']
  let g:LanguageClient_serverCommands.ocaml = ['ocaml-language-server', '--stdio']
endif
if executable('rustup')
  let g:LanguageClient_serverCommands.rust = ['rustup', 'run', 'nightly', 'rls']
endif
if executable('pyls')
  let g:LanguageClient_serverCommands.python = ['pyls']
endif

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

aug LanguageClientConfig
  autocmd!
  au FileType javascript let g:LanguageClient_diagnosticsEnable = 0
aug END
