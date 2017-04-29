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
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" General
" Plug 'prabirshrestha/async.vim'
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-flow.vim'
" Plug 'prabirshrestha/asyncomplete-ultisnips.vim'
" Plug 'prabirshrestha/asyncomplete-buffer.vim'
" Plug 'prabirshrestha/asyncomplete-necosyntax.vim'
" Plug 'maralla/completor.vim'         , { 'do': 'make js' }
if has('nvim')
  Plug 'Shougo/deoplete.nvim'          , { 'do': ':UpdateRemotePlugins' }
  Plug 'carlitux/deoplete-ternjs'      , { 'do': 'npm i -g tern', 'for': ['javascript'] }
  Plug 'steelsojka/deoplete-flow'      , { 'for': 'javascript' }
endif
Plug 'jiangmiao/auto-pairs'
Plug 'SirVer/ultisnips'
Plug 'duggiefresh/vim-easydir'
Plug 'jaawerth/nrun.vim'
Plug 'junegunn/fzf'                    , { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' } | Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'         , { 'on': ['<Plug>(EasyAlign)'] }
Plug 'junegunn/vim-peekaboo'
Plug 'kshenoy/vim-signature'
Plug 'ludovicchabant/vim-gutentags'
Plug 'mattn/emmet-vim'                 , { 'for': ['html', 'htmldjango', 'jinja', 'jinja2', 'twig', 'javascript.jsx'] }
Plug 'mbbill/undotree'                 , { 'on': ['UndotreeToggle'] }
Plug 'mhinz/vim-grepper'
Plug 'mhinz/vim-sayonara'              , { 'on': 'Sayonara' }
Plug 'scrooloose/nerdtree'             , { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
  \| Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
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
Plug 'metakirby5/codi.vim'
Plug 'Shougo/echodoc.vim'
Plug 'chr4/sslsecure.vim'

if executable('tmux')
  Plug 'wellle/tmux-complete.vim'
  Plug 'christoomey/vim-tmux-navigator'
endif

" Syntax
" Plug 'the-lambda-church/merlin'    , { 'for': ['ocaml', 'reason'] }
Plug 'ap/vim-css-color'                , { 'for': ['css', 'sass', 'scss', 'less', 'stylus'] }
Plug 'moll/vim-node'                   , { 'for': ['javascript'] }
Plug 'sheerun/vim-polyglot'
Plug 'stephenway/postcss.vim'          , { 'for': ['css'] }

" Linters & Code quality
Plug 'editorconfig/editorconfig-vim'   , { 'on': [] }
Plug 'w0rp/ale'                        , { 'do': 'npm i -g stylelint' }
Plug 'sbdchd/neoformat'                , { 'on': 'Neoformat', 'do': 'npm i -g prettier stylefmt' }

" Themes, UI & eye cnady
Plug 'ahmedelgabri/one-dark.vim'
Plug 'joshdick/onedark.vim'
Plug 'tomasiser/vim-code-dark'
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'vim-airline/vim-airline'
  \ | Plug 'vim-airline/vim-airline-themes'
Plug 'w0ng/vim-hybrid'
Plug 'liuchengxu/space-vim-dark'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/vim-gista'
Plug 'lambdalisue/gina.vim'

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

let g:echodoc_enable_at_startup=1

let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

let g:completor_filetype_map = {'javascript.jsx': 'javascript'}
let g:completor_completion_delay = 10

" Tab completion.
" inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"

" let g:UltiSnipsExpandTrigger="<c-e>"
" call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
"     \ 'name': 'ultisnips',
"     \ 'whitelist': ['*'],
"     \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
"     \ }))

" call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
"     \ 'name': 'buffer',
"     \ 'whitelist': ['*'],
"     \ 'blacklist': ['go'],
"     \ 'completor': function('asyncomplete#sources#buffer#completor'),
"     \ }))

" au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#flow#get_source_options({
"     \ 'name': 'flow',
"     \ 'whitelist': ['javascript', 'javascript.jsx'],
"     \ 'completor': function('asyncomplete#sources#flow#completor'),
"     \ 'config': {
"     \    'prefer_local': 1,
"     \    'flowbin_path': nrun#Which('flow')
"     \  },
"     \ }))

" au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#necosyntax#get_source_options({
"     \ 'name': 'necosyntax',
"     \ 'whitelist': ['*'],
"     \ 'completor': function('asyncomplete#sources#necosyntax#completor'),
"     \ }))

" Profiling. {{{
" Start profiling. Optional arg: logfile path.
if len(get(g:, 'profile', ''))
  call functions#ProfileStart(g:profile)
endif
if 0
  call functions#ProfileStart()
endif
" }}}

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


