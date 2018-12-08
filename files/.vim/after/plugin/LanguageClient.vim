if !exists(':LanguageClientStart')
  finish
endif

let g:LanguageClient_autoStart = 1
let g:LanguageClient_completionPreferTextEdit = 1
" let g:LanguageClient_hasSnippetSupport = 0
" let g:LanguageClient_loggingLevel='DEBUG'
let g:LanguageClient_serverCommands = {}

" Requires https://github.com/haskell/haskell-ide-engine
" Requires https://github.com/snoe/clojure-lsp & is installed by zplugin
let s:LSP_CONFIG = {
      \'flow-language-server': {
      \    'condition': executable('flow'),
      \    'command': ['flow-language-server', '--stdio'],
      \    'language': ['javascript', 'javascript.jsx']
      \  },
      \'javascript-typescript-stdio': {
      \    'condition': !(executable('flow') && executable('flow-language-server')),
      \    'command': ['javascript-typescript-stdio'],
      \    'language': ['javascript', 'javascript.jsx']
      \  },
      \'ocaml-language-server': {
      \    'command': ['ocaml-language-server', '--stdio'],
      \    'language': ['ocaml', 'reason']
      \  },
      \'pyls': {
      \    'command': ['pyls'],
      \    'language': ['python']
      \  },
      \'rls': {
      \    'command': ['rust', 'run', 'stable', 'rls'],
      \    'language': ['rust']
      \  },
      \'hie-wrapper': {
      \    'command': ['hie-wrapper'],
      \    'language': ['haskell']
      \  },
      \'bash-language-server': {
      \    'command': ['bash-language-server', 'start'],
      \    'language': ['sh', 'bash']
      \  },
      \'docker-langserver': {
      \    'command': ['docker-langserver', '--stdio'],
      \    'language': ['dockerfile']
      \  },
      \'clojure-lsp': {
      \    'command': ['clojure-lsp'],
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
