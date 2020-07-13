scriptencoding utf-8

if !has('nvim')
  " Don't load lsp in vim
  let g:nvim_lsp=1
  finish
endif

let g:UltiSnipsExpandTrigger='<c-u>'
let g:UltiSnipsJumpForwardTrigger='<c-j>'
let g:UltiSnipsJumpBackwardTrigger='<c-k>'

let g:completion_enable_snippet = 'UltiSnips'
" Change the completion source automatically if no completion availabe
let g:completion_auto_change_source = 1
" Delete on completion
let g:completion_trigger_on_delete = 1
let g:completion_chain_complete_list = [
      \{'complete_items': ['lsp', 'snippet', 'buffers']},
      \{'mode': '<c-p>'},
      \{'mode': '<c-n>'}
      \]

" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <c-p> completion#trigger_completion()
imap <localleader>j <Plug>(completion_prev_source)
imap <localleader>k <Plug>(completion_prev_source)


function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ completion#trigger_completion()

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert

" Avoid showing message extra message when using completion
" set shortmess+=c
