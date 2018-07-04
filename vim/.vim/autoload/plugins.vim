scriptencoding utf-8

let s:VIM_PLUG=expand($VIMHOME.'/autoload/plug.vim')
let s:VIM_PLUG_FOLDER=expand($VIMHOME.'/plugged')

function! plugins#installVimPlug() abort
  " Automatic installation
  " https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation
  execute 'silent !curl -fLo '.s:VIM_PLUG.' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  augroup MyVimPlug
    autocmd!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endfunction

" https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
function! plugins#If(cond, ...)
  let l:opts = get(a:000, 0, {})
  return a:cond ? l:opts : extend(l:opts, { 'on': [], 'for': [] })
endfunction

function! plugins#loadPlugins() abort
  call plug#begin(s:VIM_PLUG_FOLDER)
  " General {{{
  Plug 'https://github.com/tpope/vim-sensible', plugins#If(!has('nvim'))
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

  Plug 'https://github.com/SirVer/ultisnips'
  Plug 'https://github.com/jiangmiao/auto-pairs'
  Plug 'https://github.com/duggiefresh/vim-easydir'
  if !empty(glob('~/.zplugin/plugins/junegunn---fzf'))
    set runtimepath+=~/.zplugin/plugins/junegunn---fzf
    Plug 'https://github.com/junegunn/fzf.vim'
  endif
  Plug 'https://github.com/mbbill/undotree', { 'on': ['UndotreeToggle'] }
  Plug 'https://github.com/mhinz/vim-grepper', { 'on': ['Grepper'] }
  Plug 'https://github.com/mhinz/vim-sayonara', { 'on': 'Sayonara' }
  Plug 'https://github.com/mhinz/vim-startify'
  Plug 'https://github.com/Shougo/unite.vim'
        \| Plug 'https://github.com/Shougo/vimfiler.vim', { 'on': ['VimFiler', 'VimFilerExplorer'] }
  Plug 'https://github.com/tpope/tpope-vim-abolish'
  Plug 'https://github.com/tpope/vim-apathy'
  Plug 'https://github.com/tpope/vim-characterize'
  Plug 'https://github.com/tpope/vim-commentary'
  Plug 'https://github.com/tpope/vim-eunuch'
  Plug 'https://github.com/tpope/vim-repeat'
  Plug 'https://github.com/tpope/vim-speeddating'
  Plug 'https://github.com/tpope/vim-surround'
  let g:surround_indent = 0
  let g:surround_no_insert_mappings = 1

  Plug 'https://github.com/junegunn/vim-easy-align'
  Plug 'https://github.com/junegunn/vim-peekaboo'
  Plug 'https://github.com/wincent/loupe'
  Plug 'https://github.com/wincent/terminus'
  Plug 'https://github.com/wellle/targets.vim'
  Plug 'https://github.com/nelstrom/vim-visual-star-search'
  Plug 'https://github.com/christoomey/vim-tmux-navigator', plugins#If(executable('tmux') && !empty($TMUX))
  let g:tmux_navigator_disable_when_zoomed = 1

  if executable('trans')
    Plug 'https://github.com/VincentCordobes/vim-translate', { 'on': ['Translate', 'TranslateReplace', 'TranslateClear'] }
  endif
  Plug 'https://github.com/vimwiki/vimwiki', { 'branch': 'dev' }
  " }}}

  " Autocomplete {{{
  Plug 'https://github.com/autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash ./install.sh' }
  Plug 'https://github.com/othree/csscomplete.vim'
  if has('nvim')
    Plug 'https://github.com/deanmorin/nvim-completion-manager', { 'branch': 'python37' }
    Plug 'https://github.com/roxma/nvim-cm-tern', plugins#If(!executable('flow'), { 'do': 'yarn global add tern && yarn' })
    Plug 'https://github.com/Shougo/neco-vim'
  endif
  " }}}

  " Syntax {{{
  Plug 'https://github.com/chrisbra/Colorizer'
  let g:colorizer_auto_filetype='sass,scss,stylus,css,html,html.twig,twig'

  Plug 'https://github.com/reasonml-editor/vim-reason-plus'
  Plug 'https://github.com/jez/vim-github-hub'
  Plug 'https://github.com/sheerun/vim-polyglot'
  let g:polyglot_disabled = ['javascript', 'jsx', 'markdown']

  Plug 'https://github.com/chemzqm/vim-jsx-improve'
  Plug 'https://github.com/mzlogin/vim-markdown-toc'
  Plug 'https://github.com/direnv/direnv.vim'
  " Linters & Code quality {{{
  Plug 'https://github.com/w0rp/ale', { 'do': 'yarn global add prettier' }
  " }}}

  " Themes, UI & eye candy {{{
  Plug 'https://github.com/tomasiser/vim-code-dark'
  Plug 'https://github.com/tyrannicaltoucan/vim-deep-space'
  Plug 'https://github.com/morhetz/gruvbox'
  Plug 'https://github.com/icymind/NeoSolarized'
  Plug 'https://github.com/rakr/vim-two-firewatch'
  Plug 'https://github.com/logico-dev/typewriter'
  Plug 'https://github.com/agreco/vim-citylights'
  Plug 'https://github.com/atelierbram/Base2Tone-vim'
  " minimal
  Plug 'https://github.com/andreypopp/vim-colors-plain'
  Plug 'https://github.com/owickstrom/vim-colors-paramount'
  " }}}

  " Git {{{
  Plug 'https://github.com/airblade/vim-gitgutter'
  Plug 'https://github.com/lambdalisue/vim-gista'
  Plug 'https://github.com/tpope/vim-fugitive'
  Plug 'https://github.com/tpope/vim-rhubarb'
  " }}}

  " Writing {{{
  Plug 'https://github.com/junegunn/goyo.vim', { 'on': ['Goyo']}
  Plug 'https://github.com/junegunn/limelight.vim', { 'on': ['Limelight'] }
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
