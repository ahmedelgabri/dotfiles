silent! match None
setl nonumber
if has('&winblend')
  setl winblend=20
endif

let b:undo_ftplugin = 'setl nonumber< winblend<'
