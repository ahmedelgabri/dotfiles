if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ g:VIM_ROOT . '/ultisnips',
      \ g:VIM_ROOT . '/ultisnips-private'
      \ ]
let g:UltiSnipsEditSplit='context'
