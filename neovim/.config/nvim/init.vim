scriptencoding utf-8
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
if has('nvim')
  Plug 'roxma/nvim-completion-manager'
  " https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
  " Maybe I should do this instead https://github.com/junegunn/vim-plug/wiki/faq#loading-plugins-manually
  Plug 'roxma/nvim-cm-tern', empty(glob(getcwd() .'/.flowconfig')) ? { 'do': 'npm i' } : { 'on': [], 'do': 'npm i' }
  Plug 'roxma/ncm-flow', !empty(glob(getcwd() .'/.flowconfig')) ? {} : { 'on': [] }
  Plug 'Shougo/neco-vim'
  Plug 'roxma/ncm-github'
endif

Plug 'jiangmiao/auto-pairs'
Plug 'SirVer/ultisnips'
Plug 'duggiefresh/vim-easydir'
Plug 'jaawerth/nrun.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' }
  \| Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align', { 'on': ['<Plug>(EasyAlign)'] }
Plug 'junegunn/vim-peekaboo'
Plug 'ludovicchabant/vim-gutentags'
Plug 'mbbill/undotree', { 'on': ['UndotreeToggle'] }
Plug 'mhinz/vim-grepper', { 'on': ['Grepper'] }
Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
  \| Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-speeddating'
Plug 'wellle/targets.vim'
Plug 'wincent/loupe'
Plug 'wincent/pinnacle'
Plug 'wincent/terminus'
Plug 'mhinz/vim-startify'
Plug 'kepbod/quick-scope'
Plug 'nelstrom/vim-visual-star-search'
Plug 'tpope/tpope-vim-abolish'
Plug 'kshenoy/vim-signature'
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeEnable' }
Plug 'tpope/vim-projectionist'
Plug 'Valloric/MatchTagAlways', { 'for': ['html', 'xml', 'jinja2'] }
let g:mta_filetypes = {
    \ 'html' : 1,
    \ 'xml' : 1,
    \ 'jinja2' : 1,
    \}

if executable('tmux')
  Plug 'christoomey/vim-tmux-navigator'
  let g:tmux_navigator_disable_when_zoomed = 1
endif

" Syntax
Plug 'ap/vim-css-color'
Plug 'sheerun/vim-polyglot'
Plug 'rhysd/npm-filetypes.vim'
Plug 'jez/vim-github-hub'

" Linters & Code quality
Plug 'editorconfig/editorconfig-vim', { 'on': [] }
Plug 'w0rp/ale', { 'do': 'npm i -g stylelint eslint' }
Plug 'sbdchd/neoformat', { 'on': 'Neoformat', 'do': 'npm i -g prettier' }

" Themes, UI & eye cnady
Plug 'ahmedelgabri/one-dark.vim'
Plug 'rakr/vim-one'
Plug 'tomasiser/vim-code-dark'
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
Plug 'w0ng/vim-hybrid'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'gregsexton/gitv'
Plug 'lambdalisue/vim-gista'
Plug 'lambdalisue/gina.vim'

" Writing
Plug 'junegunn/goyo.vim', { 'on': ['Goyo']}
Plug 'junegunn/limelight.vim', { 'on': ['Limelight'] }

call plug#end()

syntax enable
filetype plugin indent on
"
" Load matchit.vim, but only if the user hasn't installed a newer version.
" https://github.com/tpope/vim-sensible/blob/master/plugin/sensible.vim#L88
" neovim loads it automatically see `:h matchit`
if !has('nvim') && !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &runtimepath) ==# ''
  runtime! macros/matchit.vim
endif

" Global paths for some executables that are needed for a couple of plugins
" Neoformat, ale, etc...
"================================================================================

let g:current_flow_path = nrun#Which('flow')
let g:current_prettier_path = nrun#Which('prettier')

" Plugins settings
"================================================================================
" this needs to be here ¯\_(ツ)_/¯
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Some crazy magic to make nvim-completion-manager & UltiSnips work nicely together using `<Tab>`
" It doesn't work when added to plugin/after/ultisnips.vim so for now it's here
" https://github.com/roxma/nvim-completion-manager/issues/12#issuecomment-284196219
" @TODO: Move this to autoload
let g:UltiSnipsExpandTrigger = '<Plug>(ultisnips_expand)'
let g:UltiSnipsJumpForwardTrigger = '<Plug>(ultisnips_expand)'
let g:UltiSnipsJumpBackwardTrigger = '<Plug>(ultisnips_backward)'
let g:UltiSnipsListSnippets = '<Plug>(ultisnips_list)'
let g:UltiSnipsRemoveSelectModeMappings = 0

vnoremap <expr> <Plug>(ultisnip_expand_or_jump_result) g:ulti_expand_or_jump_res?'':"\<Tab>"
inoremap <expr> <Plug>(ultisnip_expand_or_jump_result) g:ulti_expand_or_jump_res?'':"\<Tab>"
imap <silent> <expr> <Tab> (pumvisible() ? "\<C-n>" : "\<C-r>=UltiSnips#ExpandSnippetOrJump()\<cr>\<Plug>(ultisnip_expand_or_jump_result)")
xmap <Tab> <Plug>(ultisnips_expand)
smap <Tab> <Plug>(ultisnips_expand)

vnoremap <expr> <Plug>(ultisnips_backwards_result) g:ulti_jump_backwards_res?'':"\<S-Tab>"
inoremap <expr> <Plug>(ultisnips_backwards_result) g:ulti_jump_backwards_res?'':"\<S-Tab>"
imap <silent> <expr> <S-Tab> (pumvisible() ? "\<C-p>" : "\<C-r>=UltiSnips#JumpBackwards()\<cr>\<Plug>(ultisnips_backwards_result)")
xmap <S-Tab> <Plug>(ultisnips_backward)
smap <S-Tab> <Plug>(ultisnips_backward)

" optional
inoremap <silent> <c-u> <c-r>=cm#sources#ultisnips#trigger_or_popup("\<Plug>(ultisnips_expand)")<cr>

" Profiling. {{{
"================================================================================

" Start profiling. Optional arg: logfile path.
if len(get(g:, 'profile', ''))
  call functions#ProfileStart(g:profile)
endif
if 0
  call functions#ProfileStart()
endif
" }}}

" Overrrides
"================================================================================
let s:vimrc_local = $HOME . '/.vimrc.local'
if filereadable(s:vimrc_local)
  execute 'source ' . s:vimrc_local
endif

" Project specific override
"================================================================================
let s:vimrc_project = $PWD . '/.local.vim'
if filereadable(s:vimrc_project)
  execute 'source ' . s:vimrc_project
endif

" After this file is sourced, plug-in code will be evaluated.
" See ~/.vim/after for files evaluated after that.
" See `:scriptnames` for a list of all scripts, in evaluation order.
" Launch Vim with `vim --startuptime vim.log` for profiling info.
"
" To see all leader mappings, including those from plug-ins:
"
"   vim -c 'set t_te=' -c 'set t_ti=' -c 'map <space>' -c q | sort
