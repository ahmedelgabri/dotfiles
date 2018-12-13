if !exists('g:critiq_loaded')
  finish
endif

command! -nargs=* Critiq :silent! packadd critiq.vim | Critiq
