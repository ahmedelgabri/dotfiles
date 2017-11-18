let s:VIM_MINPAC_FOLDER = g:VIM_CONFIG_FOLDER . '/pack/minpack'
" Automatic installation {{{
if empty(glob(s:VIM_MINPAC_FOLDER))
  silent !git clone https://github.com/k-takata/minpac.git s:VIM_MINPAC_FOLDER.'/pack/minpac/opt/minpac'
  autocmd VimEnter * call minpac#update() | source $MYVIMRC
endif

silent! packadd minpac

if !exists('*minpac#init')
  finish
endif

command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update()
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()

call minpac#init()
call minpac#add('k-takata/minpac', {'type': 'opt'})

" Autocompletion {{{
call minpac#add('autozimu/LanguageClient-neovim', { 'type': 'opt', 'branch': 'next', 'do': '!bash ./install.sh' })
call minpac#add('roxma/nvim-completion-manager', { 'type': 'opt' })
call minpac#add('roxma/nvim-cm-tern', { 'type': 'opt', 'do': '!yarn' })
" These don't work
" call minpac#add('katsika/ncm-lbdb', { 'type': 'opt' })
call minpac#add('Shougo/neco-vim', { 'type': 'opt' })
call minpack#add('othree/csscomplete.vim', { 'type': 'opt'})
" call minpack#add('fszymanski/deoplete-emoji', { 'type': 'opt' })
call minpack#add('llwu/deoplete-emoji', { 'type': 'opt', 'branch': 'feature/more_emojis' })

if has('nvim')
  packadd nvim-completion-manager
  packadd LanguageClient-neovim
  " packadd ncm-lbdb
  packadd neco-vim
  packadd csscomplete.vim
  packadd deoplete-emoji
  if ! filereadable(findfile('.flowconfig', expand('%:p').';'))
    packadd nvim-cm-tern
  endif
endif
" }}}

" General {{{
if !has('nvim')
  call minpac#add('tpope/vim-sensible', { 'type': 'opt' })
  packadd vim-sensible
  if !has('nvim') " For vim
    if exists('&belloff')
      " never ring the bell for any reason
      set belloff=all
    endif
    if has('showcmd')
      " extra info at end of command line
      set showcmd
    endif
    if &term =~# '^tmux'
      let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
      let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    endif
  endif
endif
call minpac#add('jiangmiao/auto-pairs')
call minpac#add('SirVer/ultisnips')
call minpac#add('duggiefresh/vim-easydir')
if !empty(glob('/usr/local/opt/fzf'))
  set runtimepath^=/usr/local/opt/fzf
  call minpac#add('junegunn/fzf.vim', {'type': 'opt'})
  packadd fzf.vim
endif
call minpac#add('junegunn/vim-peekaboo')
call minpac#add('mbbill/undotree', { 'type': 'opt' })
call minpac#add('mhinz/vim-grepper', { 'type': 'opt' })
call minpac#add('mhinz/vim-sayonara', { 'type': 'opt' })
call minpac#add('Shougo/unite.vim')
call minpac#add('Shougo/vimfiler.vim', { 'type': 'opt' })
call minpac#add('tpope/vim-commentary')
call minpac#add('tpope/vim-repeat')
call minpac#add('tpope/vim-surround')
call minpac#add('tpope/vim-characterize')
call minpac#add('tpope/vim-speeddating')
call minpac#add('tpope/vim-eunuch')
call minpac#add('tpope/tpope-vim-abolish')
call minpac#add('wellle/targets.vim')
call minpac#add('wincent/loupe')
call minpac#add('wincent/terminus')
call minpac#add('mhinz/vim-startify')
call minpac#add('nelstrom/vim-visual-star-search')
" call minpac#add('tpope/vim-projectionist') " for some reason, makes fzf extremely slow
call minpac#add('ap/vim-buftabline')
call minpac#add('justinmk/vim-sneak')
" Nice idea, bad CPU performance still not stable
" check it later
" call minpack#add('andymass/vim-matchup')
" let g:matchup_transmute_enabled = 1
" let g:matchup_matchparen_deferred = 1
if executable('tmux')
  call minpac#add('christoomey/vim-tmux-navigator', {'type': 'opt'})
  packadd vim-tmux-navigator
  let g:tmux_navigator_save_on_switch = 1
endif
" }}}

" Syntax {{{
call minpac#add('ap/vim-css-color')
call minpac#add('reasonml-editor/vim-reason-plus')
call minpac#add('jez/vim-github-hub')
call minpac#add('sheerun/vim-polyglot')
" }}}

" Linters & Code quality {{{
call minpac#add('w0rp/ale', { 'do': '!yarn global add prettier' })
" }}}

" Git {{{
call minpac#add('airblade/vim-gitgutter')
call minpac#add('lambdalisue/vim-gista')
call minpac#add('tpope/vim-fugitive')
call minpac#add('tpope/vim-rhubarb')
" }}}

" Writing {{{
call minpac#add('junegunn/goyo.vim', { 'type': 'opt' })
command! -nargs=* Goyo :packadd goyo.vim | Goyo

call minpac#add('junegunn/limelight.vim', { 'type': 'opt' })
command! -nargs=* Limelight :packadd limelight.vim | Limelight
" }}}

" Themes, UI & eye cnady {{{
call minpac#add('rakr/vim-one', { 'type': 'opt' })
call minpac#add('tomasiser/vim-code-dark', { 'type': 'opt' })
call minpac#add('tyrannicaltoucan/vim-deep-space', { 'type': 'opt' })
call minpac#add('morhetz/gruvbox', { 'type': 'opt' })
call minpac#add('lifepillar/vim-solarized8', { 'type': 'opt' })
call minpac#add('w0ng/vim-hybrid', { 'type': 'opt' })
call minpac#add('ayu-theme/ayu-vim', { 'type': 'opt' })
call minpac#add('romainl/Apprentice', { 'type': 'opt' })
call minpac#add('AlessandroYorba/Alduin', { 'type': 'opt' })
call minpac#add('rakr/vim-two-firewatch', { 'type': 'opt' })
" }}}
