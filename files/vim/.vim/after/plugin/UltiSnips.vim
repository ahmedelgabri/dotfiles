if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ g:VIMHOME . '/ultisnips',
      \ g:VIMHOME . '/ultisnips-private'
      \ ]
let g:UltiSnipsEditSplit='context'
