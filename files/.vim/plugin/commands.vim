" Make these commonly mistyped commands still work
command! WQ wq
command! Wq wq
command! Wqa wqa
command! W w
command! Q q

" Use :C to clear hlsearch
command! C nohlsearch

command! Light set background=light
command! Dark set background=dark

" Delete the current file and clear the buffer
if exists(':Delete')
  command! Del :Delete
else
  command! Del :call delete(@%) | bdelete!
endif

command! ClearRegisters call functions#ClearRegisters()
