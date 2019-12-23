scriptencoding utf-8

let s:VIM_MINPAC_FOLDER = expand($VIMHOME . '/pack/minpac')
let s:CURRENT_FILE = expand('<sfile>')

function! plugins#install_minpac() abort
  execute '!git clone https://github.com/ahmedelgabri/minpac.git ' . expand(s:VIM_MINPAC_FOLDER . '/opt/minpac')
endfunction

command! -bang PackUpdate call plugins#load_plugins() | call minpac#update('', {'do': 'call minpac#status()'})
command! PackStatus call plugins#load_plugins() | call minpac#status()
command! PackClean call plugins#load_plugins() | call minpac#clean()

function! plugins#load_plugins() abort
  packadd minpac

  if !exists('*minpac#init')
    finish
  endif

  call minpac#init()
  call minpac#add('https://github.com/ahmedelgabri/minpac', { 'type': 'opt' })

  " General {{{
  call minpac#add('https://github.com/andymass/vim-matchup')
  call minpac#add('https://github.com/tpope/vim-sensible', { 'type': 'opt' })
  call minpac#add('https://github.com/jiangmiao/auto-pairs')
  call minpac#add('https://github.com/SirVer/ultisnips')

  " I have the bin globally, so don't build, and just grab plugin directory
  call minpac#add('https://github.com/junegunn/fzf')
  call minpac#add('https://github.com/junegunn/fzf.vim')

  call minpac#add('https://github.com/justinmk/vim-dirvish')
  call minpac#add('https://github.com/kristijanhusak/vim-dirvish-git')
  call minpac#add('https://github.com/junegunn/vim-peekaboo')
  call minpac#add('https://github.com/mbbill/undotree', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-grepper', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-sayonara', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-startify')
  call minpac#add('https://github.com/nelstrom/vim-visual-star-search')
  call minpac#add('https://github.com/tpope/tpope-vim-abolish')
  call minpac#add('https://github.com/tpope/vim-apathy')
  call minpac#add('https://github.com/tpope/vim-characterize')
  call minpac#add('https://github.com/tpope/vim-eunuch')
  call minpac#add('https://github.com/tpope/vim-projectionist')
  call minpac#add('https://github.com/tpope/vim-repeat')
  call minpac#add('https://github.com/tpope/vim-scriptease')
  call minpac#add('https://github.com/tpope/vim-surround')
  call minpac#add('https://github.com/tomtom/tcomment_vim')
  call minpac#add('https://github.com/wellle/targets.vim')
  call minpac#add('https://github.com/wincent/loupe')
  call minpac#add('https://github.com/wincent/terminus')
  call minpac#add('https://github.com/tommcdo/vim-lion')
  call minpac#add('https://github.com/liuchengxu/vista.vim')
  call minpac#add('https://github.com/christoomey/vim-tmux-navigator', {'type': 'opt'})
  " }}}

  " Autocompletion {{{
  let g:coc_global_extensions = [
        \ 'coc-conjure',
        \ 'coc-css',
        \ 'coc-emmet',
        \ 'coc-json',
        \ 'coc-phpls',
        \ 'coc-python',
        \ 'coc-rls',
        \ 'coc-tailwindcss',
        \ 'coc-tsserver',
        \ 'coc-ultisnips',
        \ 'coc-vimlsp',
        \ ]

  call minpac#add('https://github.com/neoclide/coc.nvim', {'branch': 'release'})
  " }}}

  " Syntax {{{
  call minpac#add('https://github.com/norcalli/nvim-colorizer.lua')
  call minpac#add('https://github.com/sheerun/vim-polyglot')
  call minpac#add('https://github.com/godlygeek/tabular') " required for plasticboy/vim-markdown
  call minpac#add('https://github.com/plasticboy/vim-markdown')
  call minpac#add('https://github.com/styled-components/vim-styled-components')
  call minpac#add('https://github.com/reasonml-editor/vim-reason-plus')
  call minpac#add('https://github.com/jez/vim-github-hub')
  call minpac#add('https://github.com/jxnblk/vim-mdx-js')
  call minpac#add('https://github.com/zplugin/zplugin-vim-syntax')
  function! s:go(hooktype, name) abort
    execute 'packadd ' . a:name
    GoUpdateBinaries
  endfunction
  call minpac#add('https://github.com/fatih/vim-go', {'do': function('s:go')})
  " Clojure
  call minpac#add('https://github.com/junegunn/rainbow_parentheses.vim', {'type': 'opt'})
  call minpac#add('https://github.com/guns/vim-sexp', {'type': 'opt'})
  call minpac#add('https://github.com/Olical/conjure', {'tag': 'v2.1.2', 'do': '!./bin/compile'})
  " }}}

  " Linters & Code quality {{{
  call minpac#add('https://github.com/dense-analysis/ale', { 'do': '!yarn global add prettier' })
  " }}}

  " Git {{{
  call minpac#add('https://github.com/airblade/vim-gitgutter')
  call minpac#add('https://github.com/lambdalisue/vim-gista')
  call minpac#add('https://github.com/tpope/vim-fugitive')
  call minpac#add('https://github.com/tpope/vim-rhubarb')
  call minpac#add('https://github.com/shumphrey/fugitive-gitlab.vim')
  call minpac#add('https://github.com/tommcdo/vim-fubitive')
  call minpac#add('https://github.com/rhysd/git-messenger.vim')
  " }}}

  " Writing {{{
  call minpac#add('https://github.com/junegunn/goyo.vim', { 'type': 'opt' })
  call minpac#add('https://github.com/junegunn/limelight.vim', { 'type': 'opt' })
  " }}}

  " Themes, UI & eye cnady {{{
  call minpac#add('https://github.com/andreypopp/vim-colors-plain', { 'type': 'opt' })
  call minpac#add('https://github.com/tomasiser/vim-code-dark', { 'type': 'opt' })
  call minpac#add('https://github.com/tyrannicaltoucan/vim-deep-space', { 'type': 'opt' })
  call minpac#add('https://github.com/liuchengxu/space-vim-theme', {'type': 'opt'})
  call minpac#add('https://github.com/rakr/vim-two-firewatch', { 'type': 'opt' })
  call minpac#add('https://github.com/logico-dev/typewriter', { 'type': 'opt' })
  call minpac#add('https://github.com/arzg/vim-corvine', { 'type': 'opt' })
  call minpac#add('https://github.com/arzg/vim-substrata', {'type': 'opt'})
  " }}}
endfunction

if !exists('*plugins#init')
  function! plugins#init() abort
    if !empty(glob(s:VIM_MINPAC_FOLDER))
      return
    endif
    exec 'source ' . s:CURRENT_FILE
    call plugins#install_minpac() | call plugins#load_plugins() | call minpac#update('', {'do': 'call minpac#status()'})
  endfunction
endif
