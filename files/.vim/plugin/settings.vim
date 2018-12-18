set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set termencoding=utf-8

set tabstop=4                         " spaces per tab
set softtabstop=2
set shiftwidth=2                      " spaces per tab (when shifting)
set expandtab                         " always use spaces instead of tabs

set nowrap                            " no wrap
set signcolumn=yes
set textwidth=80
" set colorcolumn=+1
" let &colorcolumn=join([&colorcolumn,81] + range(101,999), ',')

" This works with project specific `.local.vim` files, need to check why if I move
" to an autoload function it doesn't work
augroup MyLongLinesHighlight
  autocmd!
  autocmd BufWinEnter,BufEnter ?* call functions#setOverLength()
  autocmd OptionSet textwidth call functions#setOverLength()
  autocmd BufWinEnter,BufEnter * match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'  " highlight VCS conflict markers
augroup END

syntax sync minlines=256              " start highlighting from 256 lines backwards
set synmaxcol=300                     " do not highlight very long lines

set noshowmode                        " Don't Display the mode you're in. since it's already shown on the statusline

" show a navigable menu for tab completion
set wildmode=longest:full,list,full
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem,*.pyc
set wildignore+=*.swp,*~,*/.DS_Store
set tagcase=followscs

if has('syntax')
  set spellcapcheck=                  " don't check for capital letters at start of sentence
  " https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
  set spelllang=en_us,nl
  set spellsuggest=30
  let &spellfile=g:DOTFILES_VIM_FOLDER.'/spell/en.utf-8.add'
endif

set complete+=kspell

" Disable unsafe commands.
" Only run autocommands owned by me
" http://andrew.stwrt.ca/posts/project-specific-vimrc/
set secure

if has('virtualedit')
  set virtualedit=block               " allow cursor to move where there is no text in visual block mode
endif
set whichwrap=b,h,l,s,<,>,[,],~       " allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries

set completeopt+=menuone
set completeopt+=noinsert
set completeopt-=preview

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
set listchars=nbsp:░
set listchars+=eol:¬
set listchars+=tab:▷┅                 " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                      " + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
set listchars+=trail:•                " BULLET (U+2022, UTF-8: E2 80 A2)
set nojoinspaces                      " don't autoinsert two spaces after '.', '?', '!' for join command
set concealcursor=n                   " conceal in [n]ormal only

if has('windows')
  set fillchars=diff:⣿                " BOX DRAWINGS
  set fillchars+=vert:┃               " HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
  set fillchars+=fold:─
  if has('nvim')
    set fillchars=eob:\                 " Hide end of buffer ~
  endif
endif

" Configure fold status text
if has('folding')
  set foldtext=functions#NeatFoldText()
  set foldmethod=indent               " not as cool as syntax, but faster
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

" Make sure diffs are always opened in vertical splits
set diffopt+=vertical

set shortmess+=A                      " ignore annoying swapfile messages
set shortmess+=I                      " no splash screen
set shortmess+=O                      " file-read message overwrites previous
set shortmess+=T                      " truncate non-file messages in middle
set shortmess+=W                      " don't echo "[w]"/"[written]" when writing
set shortmess+=a                      " use abbreviations in messages eg. `[RO]` instead of `[readonly]`
set shortmess+=o                      " overwrite file-written messages
set shortmess+=t                      " truncate file messages at start

if has('nvim')
  " dark0 + gray
  let g:terminal_color_0 = '#282828'
  let g:terminal_color_8 = '#928374'

  " neurtral_red + bright_red
  let g:terminal_color_1 = '#cc241d'
  let g:terminal_color_9 = '#fb4934'

  " neutral_green + bright_green
  let g:terminal_color_2 = '#98971a'
  let g:terminal_color_10 = '#b8bb26'

  " neutral_yellow + bright_yellow
  let g:terminal_color_3 = '#d79921'
  let g:terminal_color_11 = '#fabd2f'

  " neutral_blue + bright_blue
  let g:terminal_color_4 = '#458588'
  let g:terminal_color_12 = '#83a598'

  " neutral_purple + bright_purple
  let g:terminal_color_5 = '#b16286'
  let g:terminal_color_13 = '#d3869b'

  " neutral_aqua + faded_aqua
  let g:terminal_color_6 = '#689d6a'
  let g:terminal_color_14 = '#8ec07c'

  " light4 + light1
  let g:terminal_color_7 = '#a89984'
  let g:terminal_color_15 = '#ebdbb2'
endif

if has('mksession')
  let &viewdir=g:DOTFILES_VIM_FOLDER.'/tmp/view' " override ~/.vim/view default
  set viewoptions=cursor,folds        " save/restore just these (with `:{mk,load}view`)
endif

if exists('$SUDO_USER')
  set nobackup                        " don't create root-owned files
  set nowritebackup                   " don't create root-owned files
else
  let &backupdir=g:DOTFILES_VIM_FOLDER.'/tmp/backup' " keep backup files out of the way
  set backupdir+=.
endif

if exists('$SUDO_USER')
  set noswapfile                      " don't create root-owned files
else
  let &directory=g:DOTFILES_VIM_FOLDER.'/tmp/swap//' " keep swap files out of the way
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
    let &undodir=g:DOTFILES_VIM_FOLDER.'/tmp/undo/' " keep undo files out of the way
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
    execute "set shada=!,'100,<500,:10000,/10000,s10,h,n".g:DOTFILES_VIM_FOLDER.'/tmp/main.shada'
    augroup MyNeovimShada
      autocmd!
      autocmd CursorHold,FocusGained,FocusLost * rshada|wshada
    augroup END
  else
    execute "set viminfo=!,'100,<500,:10000,/10000,s10,h,n".g:DOTFILES_VIM_FOLDER.'/tmp/viminfo'
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
