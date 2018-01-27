if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ $VIMHOME . '/ultisnips',
      \ $VIMHOME . '/ultisnips-private'
      \ ]
let g:UltiSnipsEditSplit='context'

