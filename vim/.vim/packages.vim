if empty(glob('~/.vim/pack/minpac'))
  !git clone https://github.com/k-takata/minpac.git ~/.vim/pack/minpac/opt/minpac
  autocmd VimEnter * call minpac#update() | source $MYVIMRC
endif

set packpath^=~/.vim
packadd minpac

if !exists('*minpac#init')
  finish
endif

command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update()
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()

call minpac#init({ 'verbose': 3 })
call minpac#add('k-takata/minpac', {'type': 'opt'})

" Autocompletion {{{
call minpac#add('autozimu/LanguageClient-neovim', { 'type': 'opt', 'do': 'UpdateRemotePlugins' })
call minpac#add('roxma/nvim-completion-manager', { 'type': 'opt' })
call minpac#add('roxma/ncm-flow', {'type': 'opt'})
call minpac#add('roxma/nvim-cm-tern', { 'type': 'opt', 'do': '!yarn' })
call minpac#add('katsika/ncm-lbdb', { 'type': 'opt' })
call minpac#add('roxma/ncm-github', { 'type': 'opt' })
call minpac#add('Shougo/neco-vim', { 'type': 'opt' })

if has('nvim')
  packadd nvim-completion-manager
  packadd LanguageClient-neovim
  packadd ncm-lbdb
  packadd ncm-github
  packadd neco-vim
  if (filereadable(findfile('.flowconfig', expand('%:p').';')))
    packadd ncm-flow
  else
    packadd nvim-cm-tern
  endif
endif
" }}}

" General {{{
if !has('nvim')
  call minpac#add('tpope/vim-sensible', { 'type': 'opt' })
  packadd vim-sensible
  if &term =~# '^tmux'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
endif
call minpac#add('SirVer/ultisnips')
call minpac#add('duggiefresh/vim-easydir')
if !empty(glob('/usr/local/opt/fzf'))
  set runtimepath+=/usr/local/opt/fzf
  call minpac#add('junegunn/fzf.vim', {'type': 'opt'})
  packadd fzf.vim
endif
call minpac#add('junegunn/vim-easy-align', { 'type': 'opt' })
call minpac#add('junegunn/vim-peekaboo')
call minpac#add('jsfaint/gen_tags.vim')
let g:loaded_gentags#gtags = 1
let g:gen_tags#ctags_auto_gen = 1
let g:gen_tags#use_cache_dir = 0
" let g:gen_tags#verbose = 1
call minpac#add('mbbill/undotree', { 'type': 'opt' })
call minpac#add('mhinz/vim-grepper', { 'type': 'opt' })
call minpac#add('mhinz/vim-sayonara', { 'type': 'opt' })
call minpac#add('Shougo/unite.vim')
call minpac#add('Shougo/vimfiler.vim', { 'type': 'opt' })
call minpac#add('tpope/vim-commentary')
call minpac#add('tpope/vim-repeat')
call minpac#add('tpope/vim-surround')
call minpac#add('tpope/vim-speeddating')
call minpac#add('tpope/vim-eunuch')
call minpac#add('wellle/targets.vim')
call minpac#add('wincent/loupe')
call minpac#add('wincent/pinnacle')
call minpac#add('wincent/terminus')
call minpac#add('mhinz/vim-startify')
call minpac#add('nelstrom/vim-visual-star-search')
call minpac#add('tpope/tpope-vim-abolish')
call minpac#add('kshenoy/vim-signature')
call minpac#add('bkad/CamelCaseMotion')
" Nice idea, bad CPU performance still not stable
" check it later
" call minpac#add('andymass/vim-matchup')
" let g:matchup_transmute_enabled = 1
" let g:matchup_matchparen_deferred = 1
call minpac#add('dhruvasagar/vim-table-mode', { 'type': 'opt' })
command! -nargs=* TableModeEnable :packadd vim-table-mode | TableModeEnable

call minpac#add('tpope/vim-projectionist')
call minpac#add('ap/vim-buftabline')
call minpac#add('majutsushi/tagbar', { 'type': 'opt' })
command! -nargs=* Tagbar :packadd tagbar | Tagbar

call minpac#add('justinmk/vim-sneak')
let g:sneak#label = 1

call minpac#add('blueyed/vim-diminactive')
let g:diminactive_use_syntax = 1
let g:diminactive_enable_focus = 1

if executable('tmux')
  call minpac#add('christoomey/vim-tmux-navigator', {'type': 'opt'})
  packadd vim-tmux-navigator
  let g:tmux_navigator_save_on_switch = 1
endif
" }}}

" Syntax {{{
call minpac#add('tpope/vim-sleuth')
call minpac#add('ap/vim-css-color')
call minpac#add('ahmedelgabri/vim-twig')
call minpac#add('reasonml-editor/vim-reason-plus')
call minpac#add('jez/vim-github-hub')
call minpac#add('Valloric/MatchTagAlways')
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
call minpac#add('sheerun/vim-polyglot')
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
      \ 'twig',
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
call minpac#add('editorconfig/editorconfig-vim')
call minpac#add('w0rp/ale', { 'do': '!yarn global add prettier' })
" }}}

" Git {{{
call minpac#add('airblade/vim-gitgutter')
call minpac#add('lambdalisue/vim-gista')
call minpac#add('lambdalisue/gina.vim')
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
call minpac#add('hauleth/blame.vim', { 'type': 'opt' })
call minpac#add('AlessandroYorba/Despacio', { 'type': 'opt' })
call minpac#add('whatyouhide/vim-gotham', { 'type': 'opt' })
" }}}


