scriptencoding utf-8

if !has('nvim')
  " Don't load lsp in vim
  let g:nvim_lsp=1
  finish
endif

" highlights
call sign_define("LspDiagnosticsErrorSign", {"text": utils#GetIcon('error'), "texthl":"LspDiagnosticsError", "linehl":"", "numhl":""})
call sign_define("LspDiagnosticsWarningSign", {"text":"⚠", "texthl":"LspDiagnosticsWarning", "linehl":"", "numhl":""})
call sign_define("LspDiagnosticsInformationSign", {"text": utils#GetIcon('warn'), "texthl":"LspDiagnosticsInformation", "linehl":"", "numhl":""})
call sign_define("LspDiagnosticsHintSign", {"text": utils#GetIcon('hint'), "texthl":"LspDiagnosticsHint", "linehl":"", "numhl":""})

highlight! link LspDiagnosticsError DiffDelete
highlight! link LspDiagnosticsWarning DiffChange
highlight! link LspDiagnosticsHint NonText

let g:completion_customize_lsp_label = {
      \ 'Function': ' [function]',
      \ 'Method': ' [method]',
      \ 'Reference': ' [refrence]',
      \ 'Enum': ' [enum]',
      \ 'Field': 'ﰠ [field]',
      \ 'Keyword': ' [key]',
      \ 'Variable': ' [variable]',
      \ 'Folder': ' [folder]',
      \ 'Snippet': ' [snippet]',
      \ 'Operator': ' [operator]',
      \ 'Module': ' [module]',
      \ 'Text': 'ﮜ[text]',
      \ 'Class': ' [class]',
      \ 'Interface': ' [interface]'
      \}

"  completion-nvim
let g:completion_enable_snippet = 'vim-vsnip'
let g:completion_auto_change_source = 1 " Change the completion source automatically if no completion availabe
let g:completion_matching_ignore_case = 1
let g:completion_trigger_on_delete = 1
let g:completion_chain_complete_list = {
      \ 'default' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'snippet']},
      \       {'complete_items': ['buffers']},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'},
      \       {'mode': 'dict'}
      \   ],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['/']}]
      \   }}
" completion: Use <Tab> and <S-Tab> to navigate through popup menu
" vsnip: Jump forward or backward between placeholders
imap <expr> <Tab> pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>'
smap <expr> <Tab> pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>'
imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
smap <expr> <S-Tab> pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'

inoremap <silent><expr> <c-p> completion#trigger_completion()
imap <localleader>j <Plug>(completion_next_source)
imap <localleader>k <Plug>(completion_prev_source)

" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~ '\s'
" endfunction
"
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ completion#trigger_completion()

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert

" Avoid showing message extra message when using completion
" set shortmess+=c
