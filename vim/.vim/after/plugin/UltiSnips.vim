if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ g:VIM_CONFIG_FOLDER . '/ultisnips',
      \ g:VIM_CONFIG_FOLDER . '/ultisnips-private'
      \ ]
let g:UltiSnipsEditSplit='context'

