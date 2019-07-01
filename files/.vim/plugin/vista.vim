if !exists(':Vista')
  finish
endif

let g:vista#renderer#enable_icon = 1
let g:vista_executive_for = {
      \ 'go': 'ctags',
      \ 'javascript': 'coc',
      \ 'typescript': 'coc',
      \ 'javascript.jsx': 'coc',
      \ 'python': 'coc',
      \ }
