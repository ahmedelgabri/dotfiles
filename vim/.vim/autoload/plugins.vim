let s:VIM_PLUG=expand($VIMHOME.'/autoload/plug.vim')
let s:VIM_PLUG_FOLDER=expand($VIMHOME.'/plugged')

function! plugins#installVimPlug() abort
  " Automatic installation {{{
  " https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation
  execute 'silent !curl -fLo '.s:VIM_PLUG.' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  augroup MyVimPlug
    autocmd!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endfunction

function! plugins#loadPlugins() abort
  " https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
  function! If(cond, ...)
    let l:opts = get(a:000, 0, {})
    return a:cond ? l:opts : extend(l:opts, { 'on': [], 'for': [] })
  endfunction

  call plug#begin(s:VIM_PLUG_FOLDER)
  " Autocomplete {{{
  Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash ./install.sh' }
  Plug 'othree/csscomplete.vim'
  if has('nvim')
    Plug 'roxma/nvim-completion-manager'
    Plug 'roxma/nvim-cm-tern', If(!executable('flow'), { 'do': 'yarn global add tern && yarn' })
    Plug 'Shougo/neco-vim'
  endif
  " }}}

  " General {{{
  Plug 'tpope/vim-sensible', If(!has('nvim'))
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

  Plug 'SirVer/ultisnips'
  Plug 'jiangmiao/auto-pairs'
  Plug 'duggiefresh/vim-easydir'
  if !empty(glob('/usr/local/opt/fzf'))
    set runtimepath+=/usr/local/opt/fzf
    Plug 'junegunn/fzf.vim'
  endif
  Plug 'junegunn/vim-peekaboo'
  Plug 'mbbill/undotree', { 'on': ['UndotreeToggle'] }
  Plug 'mhinz/vim-grepper', { 'on': ['Grepper'] }
  Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
  Plug 'Shougo/unite.vim'
        \| Plug 'Shougo/vimfiler.vim', { 'on': ['VimFiler', 'VimFilerExplorer'] }
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-characterize'
  Plug 'tpope/vim-speeddating'
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/tpope-vim-abolish'
  " Plug 'tpope/vim-projectionist' " for some reason, makes fzf extremely slow
  Plug 'wincent/terminus'
  Plug 'wellle/targets.vim'
  Plug 'wincent/loupe'
  Plug 'mhinz/vim-startify'
  Plug 'nelstrom/vim-visual-star-search'
  Plug 'unblevable/quick-scope'
  let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

  Plug 'christoomey/vim-tmux-navigator', If(executable('tmux') && !empty($TMUX))
  let g:tmux_navigator_save_on_switch = 1
  " }}}

  " Syntax {{{
  Plug 'ap/vim-css-color'
  Plug 'reasonml-editor/vim-reason-plus'
  Plug 'jez/vim-github-hub'
  Plug 'sheerun/vim-polyglot'
  Plug 'direnv/direnv.vim'
  " }}}

  " Linters & Code quality {{{
  Plug 'w0rp/ale', { 'do': 'yarn global add prettier' }
  " }}}

  " Themes, UI & eye candy {{{
  Plug 'rakr/vim-one' " very slow?
  Plug 'tomasiser/vim-code-dark'
  Plug 'tyrannicaltoucan/vim-deep-space'
  Plug 'morhetz/gruvbox'
  Plug 'lifepillar/vim-solarized8'
  Plug 'w0ng/vim-hybrid'
  Plug 'ayu-theme/ayu-vim'
  Plug 'romainl/Apprentice'
  Plug 'AlessandroYorba/Alduin'
  Plug 'rakr/vim-two-firewatch'
  Plug 'logico-dev/typewriter'
  Plug 'AlessandroYorba/Despacio'
  Plug 'agreco/vim-citylights'
  Plug 'atelierbram/Base2Tone-vim'
  " }}}

  " Git {{{
  Plug 'airblade/vim-gitgutter'
  Plug 'lambdalisue/vim-gista'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb'
  " }}}

  " Writing {{{
  Plug 'junegunn/goyo.vim', { 'on': ['Goyo']}
  Plug 'junegunn/limelight.vim', { 'on': ['Limelight'] }
  " }}}
  call plug#end()
endfunction

if !exists('*plugins#init')
  function! plugins#init() abort
    if empty(glob(s:VIM_PLUG)) || (!empty(glob(s:VIM_PLUG)) && empty(glob(s:VIM_PLUG_FOLDER)))
      call plugins#installVimPlug() | call plugins#loadPlugins()
    else
      call plugins#loadPlugins()
    endif
  endfunction
endif
