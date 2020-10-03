if !exists(':Vista')
  finish
endif

let g:vista#renderer#enable_icon = 1
let g:vista_close_on_jump = 1
let g:vista_executive_for = {
      \ 'go'        : 'ctags',
      \ 'javascript': 'nvim_lsp',
      \ 'javascript.jsx': 'nvim_lsp',
      \ 'typescript': 'nvim_lsp',
      \ 'typescript.tsx': 'nvim_lsp',
      \ 'python'    : 'nvim_lsp',
      \ }
