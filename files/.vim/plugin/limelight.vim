if !exists(':Limelight')
  finish
endif

command! -nargs=* Limelight :silent! packadd limelight.vim | Limelight
