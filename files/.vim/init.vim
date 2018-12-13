scriptencoding utf-8

                                " _ .--.
                                " ( `    )
                             " .-'      `--,
                  " _..----.. (             )`-.
                " .'_|` _|` _|(  .__,           )
               " /_|  _|  _|  _(        (_,  .-'
              " ;|  _|  _|  _|  '-'__,--'`--'
              " | _|  _|  _|  _| |
          " _   ||  _|  _|  _|  _|
        " _( `--.\_|  _|  _|  _|/
     " .-'       )--,|  _|  _|.`
    " (__, (_      ) )_|  _| /
      " `-.__.\ _,--'\|__|__/
                    " ;____;
                     " \YT/
                      " ||
                     " |""|
                     " '=='

" This is needed to keep all [n]vim files (backups, swaps, packages, etc...) in the same place
let g:DOTFILES_VIM_FOLDER = expand('$DOTFILES') . '/files/.vim'

" Skip vim plugins {{{
let g:loaded_rrhelper = 1
" Skip loading menu.vim, saves ~100ms
let g:did_install_default_menus = 1
" }}}

" Python {{{
" This must be here becasue it makes loading vim VERY SLOW otherwise
if has('nvim')
  let g:python_host_skip_check = 1
  let g:python3_host_skip_check = 1
  if executable('python2')
    let g:python_host_prog = '/usr/local/bin/python2'
  endif
  if executable('python3')
    let g:python3_host_prog = '/usr/local/bin/python3'
  endif
endif
" }}}

call plugins#init()
call functions#setupCompletion()

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
