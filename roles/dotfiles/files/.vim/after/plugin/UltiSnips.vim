if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ 'ultisnips',
      \ 'ultisnips-private'
      \ ]

let g:UltiSnipsEditSplit='context'
