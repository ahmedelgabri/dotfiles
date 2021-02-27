if !exists(':DevDocs')
  finish
endif

nmap <localleader>dd <Plug>(devdocs-under-cursor)

let g:devdocs_filetype_map = {
    \   'java': 'java',
    \   'javascript.jsx': 'react',
    \   'typescript.tsx': 'react',
    \   'javascript': 'javascript',
    \   'typescript': 'typescript',
    \   'lua': 'lua',
    \   'python': 'python',
    \ }
