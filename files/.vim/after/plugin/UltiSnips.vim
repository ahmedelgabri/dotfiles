if !exists(':UltiSnipsAddFiletypes')
  finish
endif

let g:UltiSnipsSnippetDirectories = [
      \ g:DOTFILES_VIM_FOLDER . '/ultisnips',
      \ g:DOTFILES_VIM_FOLDER . '/ultisnips-private'
      \ ]
let g:UltiSnipsEditSplit='context'
