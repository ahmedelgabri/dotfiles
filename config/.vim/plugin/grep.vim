if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

nnoremap \ :silent grep!  \| cwindow<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>
