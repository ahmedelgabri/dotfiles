set encoding=utf-8
scriptencoding utf-8

set tabstop=2                         " spaces per tab
set softtabstop=2
set shiftwidth=2                      " spaces per tab (when shifting)
set expandtab                         " always use spaces instead of tabs

set nowrap                            " no wrap
set signcolumn=yes

if exists('+emoji')
  set noemoji
endif

set textwidth=80
" set colorcolumn=+1
" let &colorcolumn=join([&colorcolumn,81] + range(101,999), ',')

" This works with project specific `.local.vim` files, need to check why if I move
" to an autoload function it doesn't work
augroup MyLongLinesHighlight
  autocmd!
  if has('nvim')
    autocmd BufWinEnter,BufEnter ?* lua require'_.autocmds'.highlight_overlength()
    " TODO: figure out why it breaks help files?
    " autocmd OptionSet textwidth lua require'_.autocmds'.highlight_overlength()
    " highlight VCS conflict markers
    autocmd BufWinEnter,BufEnter * lua require'_.autocmds'.highlight_git_markers()
  endif
augroup END

syntax sync minlines=256              " start highlighting from 256 lines backwards
set synmaxcol=300                     " do not highlight very long lines

set noshowmode                        " Don't Display the mode you're in. since it's already shown on the statusline

" show a navigable menu for tab completion
set wildmode=longest:full,list,full
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem,*.pyc
set wildignore+=*.swp,*~,*/.DS_Store
set tagcase=followscs
set tags^=./.git/tags;

if has('nvim-0.4')
  set pumblend=10
endif

if has('nvim-0.4')
  set pumheight=50
endif

if has('syntax')
  set spellcapcheck=                  " don't check for capital letters at start of sentence
  " https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
  set spelllang=en,nl
  set spellsuggest=30
  let &spellfile=g:VIMHOME.'/spell/spell.add'
endif

set complete+=kspell

" Disable unsafe commands.
" Only run autocommands owned by me
" http://andrew.stwrt.ca/posts/project-specific-vimrc/
set secure
" set exrc

if has('virtualedit')
  set virtualedit=block               " allow cursor to move where there is no text in visual block mode
endif
set whichwrap=b,h,l,s,<,>,[,],~       " allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries

set completeopt=menu,menuone,noselect

set lazyredraw                        " don't bother updating screen during macro playback

" highlight matching [{()}]
set showmatch
set title
set mouse=a

" More natural splitting
set splitbelow
set splitright

" Ignore case in search.
set ignorecase smartcase

" fix slight delay after pressing ESC then O http://ksjoberg.com/vim-esckeys.html
" set timeout timeoutlen=500 ttimeoutlen=100
set timeoutlen=1000 ttimeoutlen=0

if !has('nvim') && (v:version > 703 || v:version == 703 && has('patch541'))
  set formatoptions+=j                " remove comment leader when joining comment lines
endif
set formatoptions+=n                  " smart auto-indenting inside numbered lists
set formatoptions+=r1

" No beeping.
set visualbell

" No flashing.
set noerrorbells

" Start scrolling slightly before the cursor reaches an edge
set scrolloff=5
set sidescrolloff=5

" Scroll sideways a character at a time, rather than a screen at a time
set sidescroll=3

" yank and paste with the system clipboard
set clipboard=unnamed

" show trailing whitespace
set list
set listchars=tab:………,nbsp:░,extends:»,precedes:«,trail:·
set nojoinspaces
set concealcursor=n

if has('windows')
  set fillchars=diff:⣿                " BOX DRAWINGS
  set fillchars+=vert:┃               " HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
  set fillchars+=fold:─
  if has('nvim-0.3.1')
    set fillchars+=msgsep:‾
    set fillchars=eob:\                 " Hide end of buffer ~
  endif
  if has('nvim-0.5')
    set fillchars+=foldopen:▾,foldsep:│,foldclose:▸
  endif
endif

" Configure fold status text
if has('folding')
  set foldtext=utils#NeatFoldText()
  set foldlevelstart=99               " start unfolded
endif

if has('linebreak')
  let &showbreak='↳  '                " DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)
endif

" show where you are
set ruler

set hidden

" Make tilde command behave like an operator.
set tildeop

set updatetime=1000

" Make sure diffs are always opened in vertical splits, also match my git settings
set diffopt+=vertical,algorithm:histogram,indent-heuristic,hiddenoff
call utils#customize_diff()

set shortmess+=A                      " ignore annoying swapfile messages
set shortmess+=I                      " no splash screen
set shortmess+=O                      " file-read message overwrites previous
set shortmess+=T                      " truncate non-file messages in middle
set shortmess+=W                      " don't echo "[w]"/"[written]" when writing
set shortmess+=a                      " use abbreviations in messages eg. `[RO]` instead of `[readonly]`
set shortmess+=o                      " overwrite file-written messages
set shortmess+=t                      " truncate file messages at start

if has('mksession')
  if !has('nvim')
    let &viewdir=g:VIMDATA.'/view' " override ~/.vim/view default
  endif
  set viewoptions=cursor,folds        " save/restore just these (with `:{mk,load}view`)
endif

if exists('$SUDO_USER')
  set nobackup                        " don't create root-owned files
  set nowritebackup                   " don't create root-owned files
else
  if !has('nvim')
    let &backupdir=g:VIMDATA.'/backup' " keep backup files out of the way
  endif
  set backupdir+=.
endif

if exists('$SUDO_USER')
  set noswapfile                      " don't create root-owned files
else
  if !has('nvim')
    let &directory=g:VIMDATA.'/swap//' " keep swap files out of the way
  endif
  set directory+=.
endif

if exists('&swapsync')
  set swapsync=                       " let OS sync swapfiles lazily
endif

set updatecount=80                    " update swapfiles every 80 typed chars

if has('persistent_undo')
  if exists('$SUDO_USER')
    set noundofile                    " don't create root-owned files
  else
    if !has('nvim')
      let &undodir=g:VIMDATA.'/undo/' " keep undo files out of the way
    endif
    set undodir+=.
    set undofile                      " actually use undo files
  endif
endif

if exists('$SUDO_USER')               " don't create root-owned files
  if has('nvim')
    set shada=
  else
    set viminfo=
  endif
else
  if has('nvim')
    " default in nvim: !,'100,<50,s10,h
    set shada=!,'100,<500,:10000,/10000,s10,h
    augroup MyNeovimShada
      autocmd!
      autocmd CursorHold,FocusGained,FocusLost * rshada|wshada
    augroup END
  else
    execute "set viminfo=!,'100,<500,:10000,/10000,s10,h,n".g:VIMDATA.'/viminfo'
  endif
endif

if has('nvim')
  set inccommand=nosplit                " incremental command live feedback"
endif

if exists('&guioptions')
  " cursor behavior:
  "   - no blinking in normal/visual mode
  "   - blinking in insert-mode
  set guicursor+=n-v-c:blinkon0,i-ci:ver25-Cursor/lCursor-blinkwait30-blinkoff100-blinkon100
endif

if executable('rg')
  set grepprg=rg\ --vimgrep
  set grepformat=%f:%l:%c:%m
endif
