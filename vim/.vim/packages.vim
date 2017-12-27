let s:VIM_PLUG_FOLDER = g:VIM_CONFIG_FOLDER . '/plugged'
" Automatic installation {{{
" https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation

if empty(glob(g:VIM_CONFIG_FOLDER . '/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  augroup MyVimPlug
    autocmd!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif
" }}}

" https://github.com/junegunn/vim-plug/wiki/faq#conditional-activation
function! If(cond, ...)
  let l:opts = get(a:000, 0, {})
  return a:cond ? l:opts : extend(l:opts, { 'on': [], 'for': [] })
endfunction

call plug#begin(s:VIM_PLUG_FOLDER)
" Autocomplete {{{
if has('nvim')
  Plug 'autozimu/LanguageClient-neovim', { 'tag': 'binary-*-x86_64-apple-darwin' }
  Plug 'roxma/nvim-completion-manager'
  Plug 'roxma/nvim-cm-tern', If(!executable('flow'), { 'do': 'yarn' })
  Plug 'othree/csscomplete.vim'
  " These don't work
  " Plug 'katsika/ncm-lbdb'
  Plug 'Shougo/neco-vim'
  " Plug 'fszymanski/deoplete-emoji'
  Plug 'llwu/deoplete-emoji', { 'branch': 'feature/more_emojis' }
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
Plug 'tpope/vim-projectionist'
Plug 'wincent/terminus'
Plug 'wellle/targets.vim'
Plug 'wincent/loupe'
Plug 'mhinz/vim-startify'
Plug 'nelstrom/vim-visual-star-search'
Plug 'justinmk/vim-sneak'
" Nice idea, bad CPU performance still not stable
" check it later
" Plug 'andymass/vim-matchup'
" let g:matchup_transmute_enabled = 1
" let g:matchup_matchparen_deferred = 1

Plug 'christoomey/vim-tmux-navigator', If(executable('tmux') && !empty($TMUX))
let g:tmux_navigator_save_on_switch = 1
" }}}

" Syntax {{{
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
      \ 'slime',
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
Plug 'ayu-theme/ayu-vim'
Plug 'romainl/Apprentice'
Plug 'AlessandroYorba/Alduin'
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

