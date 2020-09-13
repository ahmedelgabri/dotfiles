silent! match None
setl nonumber
setl winblend=20
nmap <buffer> <silent>  q :q<cr>

let b:undo_ftplugin = 'setl nonumber< winblend<'
