if !(empty($TMUX) && exists('g:loaded_tmux_navigator'))
  packadd vim-tmux-navigator
  let g:tmux_navigator_disable_when_zoomed = 1
endif
