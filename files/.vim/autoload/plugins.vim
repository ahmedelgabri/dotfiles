scriptencoding utf-8

let s:VIM_MINPAC_FOLDER = expand($VIMHOME . '/pack/minpac')
let s:CURRENT_FILE = expand('<sfile>')

function! plugins#installMinpac() abort
  execute 'silent !git clone https://github.com/k-takata/minpac.git ' . expand(s:VIM_MINPAC_FOLDER . '/opt/minpac')
endfunction

function! plugins#loadPlugins() abort
  silent! packadd minpac

  if !exists('*minpac#init')
    finish
  endif

  command! -bar PackUpdate call plugins#init() | call minpac#update('', {'do': 'call minpac#status()'})
  command! -bar PackStatus call plugins#init() | call minpac#status()
  command! -bar PackClean call plugins#init() | call minpac#clean()

  call minpac#init({ 'verbose': 3 })
  call minpac#add('https://github.com/k-takata/minpac', { 'type': 'opt' })

  " General {{{
  call minpac#add('https://github.com/andymass/vim-matchup')
  call minpac#add('https://github.com/tpope/vim-sensible', { 'type': 'opt' })
  if !has('nvim')
    " Must explicitly load this before vim-sensible, becasue vim-sensible will
    " load match-it which we don't want. order is important.
    " https://github.com/andymass/vim-matchup#matchit
    silent! packadd vim-matchup
    silent! packadd vim-sensible
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
  endif
  call minpac#add('https://github.com/jiangmiao/auto-pairs')
  call minpac#add('https://github.com/SirVer/ultisnips')

  if !empty(glob($FZF_PATH))
    call minpac#add('https://github.com/junegunn/fzf.vim')
    set runtimepath^=$FZF_PATH
  endif
  call minpac#add('https://github.com/Shougo/unite.vim')
  call minpac#add('https://github.com/Shougo/vimfiler.vim', { 'type': 'opt' })
  call minpac#add('https://github.com/junegunn/vim-peekaboo')
  call minpac#add('https://github.com/junegunn/vim-easy-align')
  call minpac#add('https://github.com/mbbill/undotree', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-grepper', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-sayonara', { 'type': 'opt' })
  call minpac#add('https://github.com/mhinz/vim-startify')
  call minpac#add('https://github.com/nelstrom/vim-visual-star-search')
  call minpac#add('https://github.com/tpope/tpope-vim-abolish')
  call minpac#add('https://github.com/tpope/vim-characterize')
  call minpac#add('https://github.com/tpope/vim-apathy')
  call minpac#add('https://github.com/tpope/vim-commentary')
  call minpac#add('https://github.com/tpope/vim-eunuch')
  call minpac#add('https://github.com/tpope/vim-repeat')
  call minpac#add('https://github.com/tpope/vim-speeddating')
  call minpac#add('https://github.com/tpope/vim-surround')
  let g:surround_indent = 0
  let g:surround_no_insert_mappings = 1

  call minpac#add('https://github.com/wellle/targets.vim')
  call minpac#add('https://github.com/wincent/loupe')
  call minpac#add('https://github.com/wincent/terminus')

  if executable('tmux') && !empty($TMUX)
    call minpac#add('https://github.com/christoomey/vim-tmux-navigator', {'type': 'opt'})
    silent! packadd vim-tmux-navigator
    let g:tmux_navigator_disable_when_zoomed = 1
  endif

  if executable('trans')
    call minpac#add('https://github.com/VincentCordobes/vim-translate', {'type': 'opt'})
    command! -nargs=* Translate :silent! packadd vim-translate | Translate
    command! -nargs=* TranslateReplace :silent! packadd vim-translate | TranslateReplace
    command! -nargs=* TranslateClear :silent! packadd vim-translate | TranslateClear
  endif
  call minpac#add('https://github.com/vimwiki/vimwiki', { 'branch': 'dev' })
  " }}}

  " Autocompletion {{{
  call minpac#add('https://github.com/neoclide/coc.nvim', {'do': { -> coc#util#install()}})
  " }}}

  " Syntax {{{
  call minpac#add('https://github.com/chrisbra/Colorizer')
  let g:colorizer_auto_filetype='sass,scss,stylus,css,html,html.twig,twig'

  call minpac#add('https://github.com/reasonml-editor/vim-reason-plus')
  call minpac#add('https://github.com/jez/vim-github-hub')
  call minpac#add('https://github.com/sheerun/vim-polyglot')
  let g:polyglot_disabled = ['javascript', 'jsx', 'markdown']
  call minpac#add('https://github.com/neoclide/jsonc.vim')

  call minpac#add('https://github.com/neoclide/vim-jsx-improve')
  if executable('trans')
    call minpac#add('https://github.com/direnv/direnv.vim')
  endif

  " Linters & Code quality {{{
  call minpac#add('https://github.com/w0rp/ale', { 'do': '!yarn global add prettier' })
  " }}}

  " Git {{{
  call minpac#add('https://github.com/mhinz/vim-signify')
  call minpac#add('https://github.com/lambdalisue/vim-gista')
  call minpac#add('https://github.com/tpope/vim-fugitive')
  call minpac#add('https://github.com/tpope/vim-rhubarb')
  " }}}

  " Writing {{{
  call minpac#add('https://github.com/junegunn/goyo.vim', { 'type': 'opt' })
  command! -nargs=* Goyo :silent! packadd goyo.vim | Goyo

  call minpac#add('https://github.com/junegunn/limelight.vim', { 'type': 'opt' })
  command! -nargs=* Limelight :silent! packadd limelight.vim | Limelight
  " }}}

  " Themes, UI & eye cnady {{{
  call minpac#add('https://github.com/tomasiser/vim-code-dark', { 'type': 'opt' })
  call minpac#add('https://github.com/tyrannicaltoucan/vim-deep-space', { 'type': 'opt' })
  call minpac#add('https://github.com/morhetz/gruvbox', { 'type': 'opt' })
  call minpac#add('https://github.com/icymind/NeoSolarized', { 'type': 'opt' })
  call minpac#add('https://github.com/rakr/vim-two-firewatch', { 'type': 'opt' })
  call minpac#add('https://github.com/logico-dev/typewriter', { 'type': 'opt' })
  call minpac#add('https://github.com/agreco/vim-citylights', { 'type': 'opt'  })
  " minimal
  call minpac#add('https://github.com/andreypopp/vim-colors-plain', { 'type': 'opt' })
  " call minpac#add('https://github.com/nerdypepper/vim-colors-plain', { 'type': 'opt'  })
  call minpac#add('https://github.com/owickstrom/vim-colors-paramount', { 'type': 'opt'  })
  " }}}

  if getcwd() =~ 'lightspeed'
    call minpac#add('https://github.com/wakatime/vim-wakatime', { 'type': 'opt'  })
    silent! packadd vim-wakatime
  endif

  call minpac#add('https://github.com/GabrieleLippi/ydkjs-vim')
endfunction

if !exists('*plugins#init')
  function! plugins#init() abort
    exec 'source ' . s:CURRENT_FILE

    if empty(glob(s:VIM_MINPAC_FOLDER))
      call plugins#installMinpac() | call plugins#loadPlugins() | call minpac#update('', {'do': 'quit'})
    else
      call plugins#loadPlugins()
    endif
  endfunction
endif
