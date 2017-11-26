" Automatic installation {{{
" https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" }}}

" https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
function! PlugCond(cond, ...)
  let l:opts = get(a:000, 0, {})
  return a:cond ? l:opts : extend(l:opts, { 'on': [], 'for': [] })
endfunction

call plug#begin('~/.vim/plugged')
" Autocomplete {{{
if has('nvim')
  Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
  Plug 'roxma/nvim-completion-manager'
  " https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
  " Maybe I should do this instead https://github.com/junegunn/vim-plug/wiki/faq#loading-plugins-manually
  Plug 'roxma/nvim-cm-tern', PlugCond(empty(glob(getcwd() .'/.flowconfig')), { 'do': 'yarn' })
  Plug 'roxma/ncm-flow', PlugCond(!empty(glob(getcwd() .'/.flowconfig')))
  Plug 'othree/csscomplete.vim'
  " These don't work
  " Plug 'katsika/ncm-lbdb'
  " Plug 'roxma/ncm-github'
  Plug 'Shougo/neco-vim'
  " Plug 'fszymanski/deoplete-emoji'
  Plug 'llwu/deoplete-emoji', { 'branch': 'feature/more_emojis' }
endif
" }}}

" General {{{
if !has('nvim')
  Plug 'tpope/vim-sensible'
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
Plug 'junegunn/vim-easy-align', { 'on': ['<Plug>(EasyAlign)'] }
Plug 'junegunn/vim-peekaboo'
Plug 'jsfaint/gen_tags.vim'
let g:loaded_gentags#gtags = 1
let g:gen_tags#ctags_auto_gen = 1
let g:gen_tags#use_cache_dir = 0
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

Plug 'bkad/CamelCaseMotion'
" Nice idea, bad CPU performance still not stable
" check it later
" Plug 'andymass/vim-matchup'
" let g:matchup_transmute_enabled = 1
" let g:matchup_matchparen_deferred = 1

Plug 'blueyed/vim-diminactive'
let g:diminactive_use_syntax = 1
let g:diminactive_enable_focus = 1

if executable('tmux')
  Plug 'christoomey/vim-tmux-navigator'
  let g:tmux_navigator_save_on_switch = 1
endif
" }}}

" Syntax {{{
Plug 'tpope/vim-sleuth'
Plug 'ap/vim-css-color'
Plug 'reasonml-editor/vim-reason-plus'
Plug 'jez/vim-github-hub'
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
      \ 'ocaml',
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
" }}}

" Linters & Code quality {{{
Plug 'editorconfig/editorconfig-vim', { 'on': [] }
Plug 'w0rp/ale', { 'do': 'yarn global add prettier' }
" }}}

" Themes, UI & eye candy {{{
Plug 'rakr/vim-one' " very slow?
Plug 'tomasiser/vim-code-dark'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
Plug 'w0ng/vim-hybrid'
Plug 'whatyouhide/vim-gotham'
" }}}

" Git {{{
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/vim-gista'
Plug 'lambdalisue/gina.vim'
" }}}

" Writing {{{
Plug 'junegunn/goyo.vim', { 'on': ['Goyo']}
Plug 'junegunn/limelight.vim', { 'on': ['Limelight'] }
" }}}
call plug#end()

