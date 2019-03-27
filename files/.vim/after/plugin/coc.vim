scriptencoding utf-8

if !exists('g:did_coc_loaded')
  finish
endif

let g:coc_node_path=exepath('node')

let s:HAS_FLOATING_WINDOW = exists('##MenuPopupChanged') && exists('*nvim_open_win')

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
      \ ]

call coc#config('suggest', {
      \ 'autoTrigger': 'always',
      \ 'noselect': 0,
      \ })

call coc#config('diagnostic', {
      \ 'errorSign': '×',
      \ 'warningSign': '●',
      \ 'infoSign': '!',
      \ 'hintSign': '!',
      \ 'displayByAle': 1
      \ })

call coc#config('coc.preferences', {
      \ 'colorSupport': 1,
      \ 'hoverTarget': s:HAS_FLOATING_WINDOW > 0 ? 'float' : 'echo',
      \ 'signatureHelpTarget': s:HAS_FLOATING_WINDOW > 0 ? 'float' : 'echo',
      \ })

call coc#config('highlight', {
      \ 'colors': 1,
      \ 'disableLanguages': ['vim']
      \ })

let s:languageservers = {}
for [lsp, config] in s:LSP_CONFIG
  " COC chokes on emptykcommands https://github.com/neoclide/coc.nvim/issues/418#issuecomment-462106680"
  let s:not_empty_cmd = !empty(get(config, 'command'))
  if s:not_empty_cmd | let s:languageservers[lsp] = config | endif

  " Disable tsserver when flow is loaded
  if lsp ==# 'flow' && s:not_empty_cmd | call coc#config('tsserver', { 'enable': 0 }) | endif
endfor

if !empty(s:languageservers)
  call coc#config('languageserver', s:languageservers)
endif
