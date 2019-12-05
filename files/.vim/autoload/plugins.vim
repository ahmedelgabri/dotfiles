scriptencoding utf-8

let s:VIM_PACKAGER_FOLDER = expand($VIMHOME . '/pack/vim-packager')
let s:CURRENT_FILE = expand('<sfile>')

function! plugins#install_packager() abort
  execute 'silent !git clone https://github.com/kristijanhusak/vim-packager.git ' . expand(s:VIM_PACKAGER_FOLDER . '/opt/vim-packager')
endfunction

command! -bang PackUpdate call plugins#install_plugins() | call packager#update({'force_hooks': '<bang>'})
command! PackStatus call plugins#install_plugins() | call packager#status()
command! PackClean call plugins#install_plugins() | call packager#clean()

function! plugins#install_plugins() abort
  packadd vim-packager

  if !exists('*packager#init')
    finish
  endif

  call packager#init({'dir': s:VIM_PACKAGER_FOLDER})
  call packager#add('https://github.com/kristijanhusak/vim-packager', { 'type': 'opt' })

  " General {{{
  call packager#add('https://github.com/andymass/vim-matchup')
  call packager#add('https://github.com/tpope/vim-sensible', { 'type': 'opt' })
  call packager#add('https://github.com/jiangmiao/auto-pairs')
  call packager#add('https://github.com/SirVer/ultisnips')

  " I have the bin globally, so don't build, and just grab plugin directory
  call packager#add('https://github.com/junegunn/fzf')
  call packager#add('https://github.com/junegunn/fzf.vim')

  call packager#add('https://github.com/justinmk/vim-dirvish')
  call packager#add('https://github.com/kristijanhusak/vim-dirvish-git')
  call packager#add('https://github.com/junegunn/vim-peekaboo')
  call packager#add('https://github.com/mbbill/undotree', { 'type': 'opt' })
  call packager#add('https://github.com/mhinz/vim-grepper', { 'type': 'opt' })
  call packager#add('https://github.com/mhinz/vim-sayonara', { 'type': 'opt' })
  call packager#add('https://github.com/mhinz/vim-startify')
  call packager#add('https://github.com/nelstrom/vim-visual-star-search')
  call packager#add('https://github.com/tpope/tpope-vim-abolish')
  call packager#add('https://github.com/tpope/vim-apathy')
  call packager#add('https://github.com/tpope/vim-characterize')
  call packager#add('https://github.com/tpope/vim-commentary')
  call packager#add('https://github.com/tpope/vim-eunuch')
  call packager#add('https://github.com/tpope/vim-projectionist')
  call packager#add('https://github.com/tpope/vim-repeat')
  call packager#add('https://github.com/tpope/vim-scriptease')
  call packager#add('https://github.com/tpope/vim-surround')
  call packager#add('https://github.com/wellle/targets.vim')
  call packager#add('https://github.com/wincent/loupe')
  call packager#add('https://github.com/wincent/terminus')
  call packager#add('https://github.com/tommcdo/vim-lion')
  call packager#add('https://github.com/liuchengxu/vista.vim')
  call packager#add('https://github.com/christoomey/vim-tmux-navigator', {'type': 'opt'})
  call packager#add('https://github.com/tpope/vim-dispatch')
  let g:dispatch_no_tmux_make = 1  " Prefer job strategy even in tmux.
  " }}}

  " Autocompletion {{{
  let g:coc_global_extensions = [
        \ 'coc-css',
        \ 'coc-rls',
        \ 'coc-html',
        \ 'coc-emmet',
        \ 'coc-json',
        \ 'coc-python',
        \ 'coc-yaml',
        \ 'coc-emoji',
        \ 'coc-tsserver',
        \ 'coc-ultisnips',
        \ 'coc-phpls',
        \ 'coc-vimlsp',
        \ 'coc-github',
        \ 'coc-svg',
        \ 'coc-tailwindcss',
        \ 'coc-conjure'
        \ ]

  call packager#add('https://github.com/neoclide/coc.nvim', {'branch': 'release'})
  call packager#add('https://github.com/Shougo/echodoc.vim')
  " }}}

  " Syntax {{{
  call packager#add('https://github.com/norcalli/nvim-colorizer.lua')
  call packager#add('https://github.com/sheerun/vim-polyglot')
  call packager#add('https://github.com/godlygeek/tabular') " required for plasticboy/vim-markdown
  call packager#add('https://github.com/plasticboy/vim-markdown')
  call packager#add('https://github.com/styled-components/vim-styled-components')
  call packager#add('https://github.com/reasonml-editor/vim-reason-plus')
  call packager#add('https://github.com/jez/vim-github-hub')
  call packager#add('https://github.com/jxnblk/vim-mdx-js')
  call packager#add('https://github.com/zplugin/zplugin-vim-syntax')
  call packager#add('https://github.com/fatih/vim-go', {'do': ':GoUpdateBinaries'})
  " Clojure
  call packager#add('https://github.com/junegunn/rainbow_parentheses.vim', {'type': 'opt'})
  call packager#add('https://github.com/guns/vim-sexp', {'type': 'opt'})
  call packager#add('https://github.com/Olical/conjure', {'tag': 'v2.1.2', 'do': 'bin/compile'})
  " }}}

  " Linters & Code quality {{{
  call packager#add('https://github.com/dense-analysis/ale', { 'do': 'yarn global add prettier' })
  " }}}

  " Git {{{
  call packager#add('https://github.com/airblade/vim-gitgutter')
  call packager#add('https://github.com/lambdalisue/vim-gista')
  call packager#add('https://github.com/tpope/vim-fugitive')
  call packager#add('https://github.com/tpope/vim-rhubarb')
  call packager#add('https://github.com/shumphrey/fugitive-gitlab.vim')
  call packager#add('https://github.com/tommcdo/vim-fubitive')
  call packager#add('https://github.com/rhysd/git-messenger.vim')
  " }}}

  " Writing {{{
  call packager#add('https://github.com/junegunn/goyo.vim', { 'type': 'opt' })
  call packager#add('https://github.com/junegunn/limelight.vim', { 'type': 'opt' })
  " }}}

  " Themes, UI & eye cnady {{{
  call packager#add('https://github.com/andreypopp/vim-colors-plain', { 'type': 'opt' })
  call packager#add('https://github.com/tomasiser/vim-code-dark', { 'type': 'opt' })
  call packager#add('https://github.com/tyrannicaltoucan/vim-deep-space', { 'type': 'opt' })
  call packager#add('https://github.com/liuchengxu/space-vim-theme', {'type': 'opt'})
  call packager#add('https://github.com/rakr/vim-two-firewatch', { 'type': 'opt' })
  call packager#add('https://github.com/logico-dev/typewriter', { 'type': 'opt' })
  call packager#add('https://github.com/arzg/vim-corvine', { 'type': 'opt' })
  call packager#add('https://github.com/arzg/vim-substrata', {'type': 'opt'})
  " }}}
endfunction

if !exists('*plugins#init')
  function! plugins#init() abort
    if !empty(glob(s:VIM_PACKAGER_FOLDER))
      return
    endif
    exec 'source ' . s:CURRENT_FILE
    call plugins#install_packager() | set nomore | call plugins#install_plugins() | call packager#update({'force_hooks': 1, 'on_finish': 'quitall'})
  endfunction
endif
