if !exists(':Limelight')
  finish
endif

command! -nargs=* Limelight :packadd limelight.vim | Limelight
