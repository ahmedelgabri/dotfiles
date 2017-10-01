" vim: ft=vim
scriptencoding utf-8

" This must be here becasue it makes loading vim VERY SLOW otherwise
let g:python_host_skip_check = 1
let g:python3_host_skip_check = 1
let g:python_host_prog = '/usr/local/opt/python/libexec/bin/python'
let g:python3_host_prog = '/usr/local/bin/python3'
" let g:loaded_python_provider = 1
" let g:loaded_python3_provider = 1

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

" https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
function! PlugCond(cond, ...)
  let l:opts = get(a:000, 0, {})
  return a:cond ? l:opts : extend(l:opts, { 'on': [], 'for': [] })
endfunction

call plug#begin('~/.vim/plugged')
" General
if !has('nvim')
  Plug 'tpope/vim-sensible'
  if &term =~# '^tmux'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
endif

Plug 'tweekmonster/startuptime.vim', { 'on': ['StartupTime'] }
if has('nvim')
  Plug 'roxma/nvim-completion-manager'
  " https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
  " Maybe I should do this instead https://github.com/junegunn/vim-plug/wiki/faq#loading-plugins-manually
  Plug 'roxma/nvim-cm-tern', PlugCond(empty(glob(getcwd() .'/.flowconfig')), { 'do': 'yarn' })
  Plug 'roxma/ncm-flow', PlugCond(!empty(glob(getcwd() .'/.flowconfig')))
  Plug 'katsika/ncm-lbdb'
  Plug 'Shougo/neco-vim'
endif

Plug 'jiangmiao/auto-pairs'
Plug 'SirVer/ultisnips'
Plug 'duggiefresh/vim-easydir'
if !empty(glob('/usr/local/opt/fzf'))
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf.vim'
endif
Plug 'junegunn/vim-easy-align', { 'on': ['<Plug>(EasyAlign)'] }
Plug 'junegunn/vim-peekaboo'
Plug 'jsfaint/gen_tags.vim'
let g:loaded_gentags#gtags = 1
let g:gen_tags#ctags_auto_gen = 1
let g:gen_tags#ctags_use_cache_dir = 0
" let g:gen_tags#verbose = 1
Plug 'mbbill/undotree', { 'on': ['UndotreeToggle'] }
Plug 'mhinz/vim-grepper', { 'on': ['Grepper'] }
Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
Plug 'Shougo/unite.vim'
  \| Plug 'Shougo/vimfiler.vim', { 'on': ['VimFiler', 'VimFilerExplorer'] }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-eunuch'
Plug 'wellle/targets.vim'
Plug 'wincent/loupe'
Plug 'wincent/pinnacle'
Plug 'wincent/terminus'
Plug 'mhinz/vim-startify'
Plug 'nelstrom/vim-visual-star-search'
Plug 'tpope/tpope-vim-abolish'
Plug 'kshenoy/vim-signature'
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeEnable' }
Plug 'tpope/vim-projectionist'
Plug 'ap/vim-buftabline'
Plug 'majutsushi/tagbar', { 'on': ['Tagbar'] }
Plug 'justinmk/vim-sneak'
let g:sneak#label = 1

if executable('tmux')
  Plug 'christoomey/vim-tmux-navigator'
  let g:tmux_navigator_save_on_switch = 1
endif

" Syntax
Plug 'tpope/vim-sleuth'
Plug 'ap/vim-css-color'
Plug 'sheerun/vim-polyglot'
" These are enabled, the rest is disabled. Maybe I should install them separately instead
" https://github.com/sheerun/vim-polyglot#language-packs
" https://github.com/jackfranklin/dotfiles/blob/6c0ba96b20f70d63a8dbb2652d8ebe2241355552/vim/vimrc#L3-L22
" \ 'ansible', Needed for Jinja2?!
" \ 'clojure',
" \ 'coffee-script',
" \ 'dockerfile',
" \ 'elm',
" \ 'git',
" \ 'go',
" \ 'graphql',
" \ 'html5',
" \ 'javascript',
" \ 'json',
" \ 'jsx',
" \ 'lua',
" \ 'markdown',
" \ 'ocaml',
" \ 'php',
" \ 'python-compiler',
" \ 'python',
" \ 'ruby',
" \ 'scss',
" \ 'tmux',
" \ 'twig',
" \ 'yaml',
let g:polyglot_disabled = [
    \ 'apiblueprint',
    \ 'applescript',
    \ 'arduino',
    \ 'asciidoc',
    \ 'blade',
    \ 'c++11',
    \ 'c/c++',
    \ 'caddyfile',
    \ 'cjsx',
    \ 'cql',
    \ 'cryptol',
    \ 'crystal',
    \ 'css',
    \ 'cucumber',
    \ 'dart',
    \ 'elixir',
    \ 'emberscript',
    \ 'emblem',
    \ 'erlang',
    \ 'fish',
    \ 'glsl',
    \ 'gnuplot',
    \ 'groovy',
    \ 'haml',
    \ 'handlebars',
    \ 'haskell',
    \ 'haxe',
    \ 'i3',
    \ 'jasmine',
    \ 'jst',
    \ 'julia',
    \ 'kotlin',
    \ 'latex',
    \ 'less',
    \ 'liquid',
    \ 'livescript',
    \ 'mako',
    \ 'mathematica',
    \ 'nim',
    \ 'nix',
    \ 'nginx',
    \ 'objc',
    \ 'octave',
    \ 'opencl',
    \ 'perl',
    \ 'pgsql',
    \ 'plantuml',
    \ 'powershell',
    \ 'protobuf',
    \ 'pug',
    \ 'puppet',
    \ 'purescript',
    \ 'qml',
    \ 'r-lang',
    \ 'racket',
    \ 'ragel',
    \ 'raml',
    \ 'rspec',
    \ 'rust',
    \ 'sbt',
    \ 'scala',
    \ 'slim',
    \ 'solidity',
    \ 'stylus',
    \ 'swift',
    \ 'sxhkd',
    \ 'systemd',
    \ 'terraform',
    \ 'textile',
    \ 'thrift',
    \ 'tomdoc',
    \ 'toml',
    \ 'typescript',
    \ 'vala',
    \ 'vbnet',
    \ 'vcl',
    \ 'vm',
    \ 'vue',
    \ 'xls',
    \ 'yard'
    \ ]
Plug 'jez/vim-github-hub'
Plug 'Valloric/MatchTagAlways'
let g:mta_filetypes = {
    \ 'html' : 1,
    \ 'xhtml' : 1,
    \ 'xml' : 1,
    \ 'jinja' : 1,
    \ 'jinja2' : 1,
    \ 'twig' : 1,
    \ 'javascript' : 1,
    \ 'javascript.jsx' : 1,
    \}

" Linters & Code quality
Plug 'editorconfig/editorconfig-vim', { 'on': [] }
Plug 'w0rp/ale', { 'do': 'yarn global add prettier' }

" Themes, UI & eye cnady
Plug 'rakr/vim-one' " very slow!
Plug 'tomasiser/vim-code-dark'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
Plug 'w0ng/vim-hybrid'
Plug 'hauleth/blame.vim'
Plug 'AlessandroYorba/Despacio'
Plug 'whatyouhide/vim-gotham'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/vim-gista'
Plug 'lambdalisue/gina.vim'

" Writing
Plug 'junegunn/goyo.vim', { 'on': ['Goyo']}
Plug 'junegunn/limelight.vim', { 'on': ['Limelight'] }

call plug#end()

" Plugins settings
"================================================================================

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

" let g:profile=1
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
