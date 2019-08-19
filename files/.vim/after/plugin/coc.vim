scriptencoding utf-8

if !exists('g:did_coc_loaded')
  finish
endif

let g:coc_node_path=exepath('node')

let s:LSP_CONFIG = [
      \ ['flow', {
      \   'command': exepath('flow'),
      \   'args': ['lsp'],
      \   'filetypes': ['javascript', 'javascript.jsx'],
      \   'initializationOptions': {},
      \   'requireRootPattern': 1,
      \   'settings': {},
      \   'rootPatterns': ['.flowconfig']
      \ }],
      \ ['ocaml', {
      \   'command': exepath('ocaml-language-server'),
      \   'args': ['--stdio'],
      \   'filetypes': ['ocaml', 'reason']
      \ }],
      \ ['bash', {
      \   'command': exepath('bash-language-server'),
      \   'args': ['start'],
      \   'filetypes': ['sh', 'bash'],
      \   'ignoredRootPaths': ['~']
      \ }],
      \ ['docker', {
      \   'command': exepath('docker-langserver'),
      \   'args': ['--stdio'],
      \   'filetypes': ['dockerfile']
      \ }],
      \ ['clojure', {
      \   'command': exepath('clojure-lsp'),
      \   'filetypes': ['clojure']
      \  }],
      \ ['golang', {
      \   'command': exepath('gopls'),
      \   'filetypes': ['go'],
      \   'rootPatterns': ['go.mod', '.vim/', '.git/', '.hg/']
      \  }],
      \ ['haskell', {
      \     'command': exepath('hie-wrapper'),
      \     'rootPatterns': ['.stack.yaml', 'cabal.config', 'package.yaml'],
      \     'filetypes': ['hs', 'lhs', 'haskell'],
      \     'initializationOptions': {},
      \     'settings': {
      \       'languageServerHaskell': {
      \         'hlintOn': empty(exepath('hlint')) ? 1 : 0,
      \         'maxNumberOfProblems': 10,
      \         'completionSnippetsOn': 1
      \       }
      \     }
      \   }
      \ ]
      \]

" 'diagnostic.displayByAle' Doesn't work well, for some reason...
let g:coc_user_config = {
      \  'coc.preferences.colorSupport': 0,
      \  'coc.preferences.hoverTarget': utils#has_floating_window() ? 'float' : 'echo',
      \  'suggest.autoTrigger': 'always',
      \  'suggest.noselect': 0,
      \  'suggest.echodocSupport': 1,
      \  'suggest.floatEnable': utils#has_floating_window(),
      \  'signature.target': utils#has_floating_window() ? 'float' : 'echo',
      \  'diagnostic.errorSign': '',
      \  'diagnostic.warningSign': '',
      \  'diagnostic.infoSign': utils#GetIcon('info'),
      \  'diagnostic.hintSign': utils#GetIcon('hint'),
      \  'diagnostic.messageTarget': utils#has_floating_window() ? 'float' : 'echo',
      \  'diagnostic.refreshOnInsertMode': 1,
      \  'diagnostic.locationlist': 1,
      \  'python.linting': {
      \    'pylintUseMinimalCheckers': 0
      \   },
      \  'coc.github.filetypes': ['gitcommit', 'markdown.ghpull']
      \ }

let s:languageservers = {}
for [lsp, config] in s:LSP_CONFIG
  " COC chokes on emptykcommands https://github.com/neoclide/coc.nvim/issues/418#issuecomment-462106680"
  let s:not_empty_cmd = !empty(get(config, 'command'))
  if s:not_empty_cmd | let s:languageservers[lsp] = config | endif

  " Disable tsserver when flow is loaded
  if lsp ==# 'flow' && s:not_empty_cmd | call coc#config('tsserver', { 'enableJavascript': 0 }) | endif
endfor

if !empty(s:languageservers)
  call coc#config('languageserver', s:languageservers)
endif
