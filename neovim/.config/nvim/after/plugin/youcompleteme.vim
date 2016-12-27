" I use deoplete with neovim
if !has('nvim')
  let g:ycm_path_to_python_interpreter = '/usr/local/bin/python'
  let g:ycm_python_binary_path = '/usr/local/bin/python3'

  au! User YouCompleteMe if !has('vim_starting')
        \| call youcompleteme#Enable() | endif
endif
