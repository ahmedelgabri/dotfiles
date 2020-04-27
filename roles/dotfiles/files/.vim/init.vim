scriptencoding utf-8

let g:VIMHOME = exists('*stdpath') ? stdpath('config') : expand(exists('$XDG_CONFIG_HOME') ? $XDG_CONFIG_HOME.'/nvim' : $HOME.'/.config/nvim')
let g:VIMDATA = exists('*stdpath') ? stdpath('data')   : expand(exists('$XDG_DATA_HOME')   ? $XDG_DATA_HOME.'/nvim'   : $HOME.'/.local/share/nvim')

" Skip vim plugins {{{
let g:loaded_rrhelper = 1
" Skip loading menu.vim, saves ~100ms
let g:did_install_default_menus = 1
" }}}

" Providers {{{
" Set them directly if they are installed, otherwise disable them. To avoid the
" runtime check cost, which can be slow.
if has('nvim')
  " Python This must be here becasue it makes loading vim VERY SLOW otherwise
  let g:python_host_skip_check = 1
  if executable('python2')
    let g:python_host_prog = exepath('python2')
  else
    let g:loaded_python_provider = 0
  endif


  let g:python3_host_skip_check = 1
  if executable('python3')
    let g:python3_host_prog = exepath('python3')
  else
    let g:loaded_python3_provider = 0
  endif

  if executable('neovim-node-host')
    let g:node_host_prog = exepath('neovim-node-host')
  else
    let g:loaded_node_provider = 0
  endif

  if executable('neovim-ruby-host')
    let g:ruby_host_prog = exepath('neovim-ruby-host')
  else
    let g:loaded_ruby_provider = 0
  endif

  let g:loaded_perl_provider = 0
endif
" }}}


" leader is space, only works with double quotes around it?!
let g:mapleader="\<Space>"
let g:maplocalleader=','

call plugins#init()
call utils#setupCompletion()

" Overrrides {{{
let s:vimrc_local = $HOME . '/.vimrc.local'
if filereadable(s:vimrc_local)
  execute 'source ' . s:vimrc_local
endif
" }}}

" After this file is sourced, plug-in code will be evaluated.
" See ~/.vim/after for files evaluated after that.
" See `:scriptnames` for a list of all scripts, in evaluation order.
" Launch Vim with `vim --startuptime vim.log` for profiling info.
"
" To see all leader mappings, including those from plug-ins:
"
"   vim -c 'set t_te=' -c 'set t_ti=' -c 'map <space>' -c q | sort
