if !exists('g:critiq_loaded')
  finish
endif

command! -nargs=* Critiq :packadd critiq.vim | Critiq
