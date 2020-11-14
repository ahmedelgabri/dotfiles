silent! match None
setl nonumber
if has('&winblend')
  setl winblend=20
endif
nmap <buffer> <silent>  q :q<cr>

let b:undo_ftplugin = 'setl nonumber< winblend<'
