scriptencoding utf-8
"             __
"     __  __ /\_\    ___ ___   _ __   ___
"    /\ \/\ \\/\ \ /' __` __`\/\`'__\/'___\
"  __\ \ \_/ |\ \ \/\ \/\ \/\ \ \ \//\ \__/
" /\_\\ \___/  \ \_\ \_\ \_\ \_\ \_\\ \____\
" \/_/ \/__/    \/_/\/_/\/_/\/_/\/_/ \/____/
"
"
"================================================================================
set packpath^=~/.vim

" Python {{{
" This must be here becasue it makes loading vim VERY SLOW otherwise
if has('nvim')
  let g:python_host_skip_check = 1
  let g:python3_host_skip_check = 1
  if executable('/usr/local/opt/python/libexec/bin/python')
    let g:python_host_prog = '/usr/local/opt/python/libexec/bin/python'
  endif
  if executable('/usr/local/bin/python3')
    let g:python3_host_prog = '/usr/local/bin/python3'
  endif
  " let g:loaded_python_provider = 1
  " let g:loaded_python3_provider = 1
endif
" }}}

source ~/.dotfiles/vim/.vim/packages.vim

call functions#setupCompletion()

" Overrrides {{{
let s:vimrc_local = $HOME . '/.vimrc.local'
if filereadable(s:vimrc_local)
  execute 'source ' . s:vimrc_local
endif
" }}}

" Project specific override {{{
augroup MyVimrc
  autocmd!
  autocmd BufRead,BufNewFile * call functions#sourceProjectConfig()

  if has('nvim')
    autocmd DirChanged * call functions#sourceProjectConfig()
  endif
augroup END
" }}}

" After this file is sourced, plug-in code will be evaluated.
" See ~/.vim/after for files evaluated after that.
" See `:scriptnames` for a list of all scripts, in evaluation order.
" Launch Vim with `vim --startuptime vim.log` for profiling info.
"
" To see all leader mappings, including those from plug-ins:
"
"   vim -c 'set t_te=' -c 'set t_ti=' -c 'map <space>' -c q | sort
