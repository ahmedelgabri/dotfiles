" vim: ft=vim
"
"             __
"     __  __ /\_\    ___ ___   _ __   ___
"    /\ \/\ \\/\ \ /' __` __`\/\`'__\/'___\
"  __\ \ \_/ |\ \ \/\ \/\ \/\ \ \ \//\ \__/
" /\_\\ \___/  \ \_\ \_\ \_\ \_\ \_\\ \____\
" \/_/ \/__/    \/_/\/_/\/_/\/_/\/_/ \/____/
"
"
"================================================================================
" Vim-Plug

" Automatic installation
" https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" General
if has('nvim')
  Plug 'Shougo/deoplete.nvim'          , { 'do': ':UpdateRemotePlugins' }
  Plug 'carlitux/deoplete-ternjs'      , { 'do': 'npm i -g tern' }
  Plug 'steelsojka/deoplete-flow'      , { 'do': 'npm i -g flow-bin' }
else
  Plug 'Valloric/YouCompleteMe'        , { 'do': './install.py --tern-completer' }
  Plug 'flowtype/vim-flow'             , { 'for': ['javascript'], 'do': 'npm i -g flow-bin' }
endif
Plug 'Raimondi/delimitMate'
Plug 'SirVer/ultisnips'
Plug 'duggiefresh/vim-easydir'
Plug 'dyng/ctrlsf.vim'
Plug 'jaawerth/nrun.vim'
Plug 'junegunn/fzf'                    , { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' } | Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'         , { 'on': ['<Plug>(EasyAlign)'] }
Plug 'junegunn/vim-peekaboo'
Plug 'kshenoy/vim-signature'
Plug 'ludovicchabant/vim-gutentags'
Plug 'mattn/emmet-vim'                 , { 'for': ['html', 'htmldjango', 'jinja', 'jinja2', 'twig'] }
Plug 'mbbill/undotree'                 , { 'on': ['UndotreeToggle'] }
Plug 'mhinz/vim-grepper'
Plug 'mhinz/vim-sayonara'              , { 'on': 'Sayonara' }
Plug 'scrooloose/nerdtree'             , { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'Xuyuanp/nerdtree-git-plugin'     , { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'ternjs/tern_for_vim'             , { 'for': ['javascript'], 'do': 'npm i', 'on': [] }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'wellle/targets.vim'
Plug 'wincent/loupe'
Plug 'wincent/pinnacle' " this is only used in plugins/after/loupe.vim is it worth it?
Plug 'wincent/terminus'
Plug 'mhinz/vim-startify'
Plug 'beloglazov/vim-online-thesaurus' , { 'on': ['Thesaurus', 'OnlineThesaurusCurrentWord'] }
Plug 'kepbod/quick-scope'

if executable('tmux')
  Plug 'wellle/tmux-complete.vim'
  Plug 'christoomey/vim-tmux-navigator'
endif

" Syntax
" Plug 'the-lambda-church/merlin'    , { 'for': ['ocaml', 'reason'] }
Plug 'ap/vim-css-color'                , { 'for': ['css', 'sass', 'scss', 'less', 'stylus'] }
Plug 'kewah/vim-stylefmt'              , { 'on':  ['Stylefmt', 'StylefmtVisual'] }
Plug 'moll/vim-node'                   , { 'for': ['javascript'] }
Plug 'sheerun/vim-polyglot'
Plug 'stephenway/postcss.vim'          , { 'for': ['css'] }

" Linters & Code quality
Plug 'editorconfig/editorconfig-vim'   , { 'on': [] }
Plug 'benekastah/neomake'              , { 'do': 'npm i -g flow-vim-quickfix' }

" Themes, UI & eye cnady
Plug 'ahmedelgabri/one-dark.vim'
Plug 'atelierbram/Base2Tone-vim'
Plug 'chriskempson/base16-vim'
Plug 'joshdick/onedark.vim'
Plug 'morhetz/gruvbox'
Plug 'romainl/flattened' " Solarized, without the bullshit.
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'w0ng/vim-hybrid'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/vim-gista'
Plug 'lambdalisue/vim-gita'
Plug 'tpope/vim-fugitive' | Plug 'junegunn/gv.vim'                 , { 'on': 'GV' }

" Writing
Plug 'junegunn/goyo.vim'               , { 'on': ['Goyo']}
Plug 'junegunn/limelight.vim'          , { 'on': ['Limelight'] }

call plug#end()

syntax enable
filetype plugin indent on
"
" Load matchit.vim, but only if the user hasn't installed a newer version.
" https://github.com/tpope/vim-sensible/blob/master/plugin/sensible.vim#L88
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif

" Plugins settings
"================================================================================
" See after/plugin/deoplete.vim
let g:deoplete#enable_at_startup = 1

let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Tab completion.
" inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

" Overrrides
" =================
let s:vimrc_local = $HOME . '/.vimrc.local'
if filereadable(s:vimrc_local)
  execute 'source ' . s:vimrc_local
endif

" Project specific override
" =========================
let s:vimrc_project = $PWD . '/.local.vim'
if filereadable(s:vimrc_project)
  execute 'source ' . s:vimrc_project
endif


