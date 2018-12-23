if !exists(':LanguageClientStart')
  finish
endif

let g:LanguageClient_autoStart = 1
let g:LanguageClient_completionPreferTextEdit = 1
" let g:LanguageClient_hasSnippetSupport = 0
" let g:LanguageClient_loggingLevel='DEBUG'
let g:LanguageClient_diagnosticsList = 'Location'
let g:LanguageClient_diagnosticsSignsMax = 0

" Requires https://github.com/haskell/haskell-ide-engine
" Requires https://github.com/snoe/clojure-lsp & is installed by zplugin
" `flow lsp` command is available but currently experimental
let g:LanguageClient_serverCommands = {}
let s:LSP_CONFIG = {
      \'flow-language-server': {
      \    'condition': executable('flow') && filereadable('.flowconfig'),
      \    'command': [exepath('flow-language-server'), '--stdio'],
      \    'language': ['javascript', 'javascript.jsx']
      \  },
      \'javascript-typescript-stdio': {
      \    'condition': !executable('flow') || filereadable('tsconfig.json'),
      \    'command': [exepath('javascript-typescript-stdio')],
      \    'language': ['javascript', 'javascript.jsx', 'typescript']
      \  },
      \'ocaml-language-server': {
      \    'command': [exepath('ocaml-language-server'), '--stdio'],
      \    'language': ['ocaml', 'reason']
      \  },
      \'pyls': {
      \    'command': [exepath('pyls')],
      \    'language': ['python']
      \  },
      \'rls': {
      \    'command': [exepath('rust'), 'run', 'stable', 'rls'],
      \    'language': ['rust']
      \  },
      \'hie-wrapper': {
      \    'command': [exepath('hie-wrapper')],
      \    'language': ['haskell']
      \  },
      \'bash-language-server': {
      \    'command': [exepath('bash-language-server'), 'start'],
      \    'language': ['sh', 'bash']
      \  },
      \'docker-langserver': {
      \    'command': [exepath('docker-langserver'), '--stdio'],
      \    'language': ['dockerfile']
      \  },
      \'clojure-lsp': {
      \    'command': [exepath('clojure-lsp')],
      \    'language': ['clojure']
      \  },
      \}

for [lsp, config] in items(s:LSP_CONFIG)
  if get(config, 'condition', v:true) && executable(lsp)
    for lang in get(config, 'language')
      let g:LanguageClient_serverCommands[lang] = get(config, 'command')
    endfor
  endif
endfor

" augroup LanguageClientConfig
"   autocmd!
"   autocmd FileType javascript,javascript.jsx let g:LanguageClient_diagnosticsEnable = 0
" augroup END

if !has('nvim')
  aug VIM_COMPLETION
    au!
    autocmd FileType javascript,javascript.jsx setlocal omnifunc=LanguageClient#complete
    autocmd FileType python setlocal omnifunc=LanguageClient#complete
    autocmd FileType rust setlocal omnifunc=LanguageClient#complete
    autocmd FileType ocaml,reason setlocal omnifunc=LanguageClient#complete
    autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS noci
  aug END
end

aug lang_client_mappings
  au!
  au User LanguageClientStarted nnoremap <buffer> K :call LanguageClient#textDocument_hover()<CR>
  au User LanguageClientStarted nnoremap <buffer> gd :call LanguageClient#textDocument_definition()<CR>
  au User LanguageClientStarted nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
augroup END
