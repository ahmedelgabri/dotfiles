if has('nvim')
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
end

if !has('nvim')
  set nocompatible
  set encoding=utf-8
  set autoindent                        " maintain indent of current line
  set backspace=indent,start,eol        " allow unrestricted backspacing in insert mode
  " Display as much as possibe of a window's last line.
  set display+=lastline
  set laststatus=2
  set ttyfast
  set wildmenu
  if &term =~# '^tmux'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
endif

set showtabline=2
set laststatus=2
set tabline="%1T"

" set highlight+=@:ColorColumn          " ~/@ at end of window, 'showbreak'
" set highlight+=N:DiffText             " make current line number stand out a little
" set highlight+=c:LineNr               " blend vertical separators with line numbers

set expandtab                         " always use spaces instead of tabs
set tabstop=2                         " spaces per tab
set softtabstop=2
set shiftround                        " always indent by multiple of shiftwidth
set shiftwidth=2                      " spaces per tab (when shifting)

set nowrap                            " no wrap

set textwidth=100
set colorcolumn=+1

syntax sync minlines=256 " start highlighting from 256 lines backwards
set synmaxcol=300        " do not highlith very long lines
" set re=1                 " use explicit old regexpengine, seems to be more faster

set number                            " show line numbers in gutter

if exists('+relativenumber')
  set relativenumber                  " show relative numbers in gutter
endif

if has('showcmd')
  set showcmd                         " extra info at end of command line
endif

set noshowmode                        " Don't Display the mode you're in. since it's already shown on the statusline

" show a navigable menu for tab completion
set wildmode=longest,list,full
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem,*.pyc
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*
set wildignore+=*/tmp/librarian/*,*/.vagrant/*,*/.kitchen/*,*/vendor/cookbooks/*
set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*
set wildignore+=*.swp,*~,._*,*.jpg,*.png,*.gif,*.jpeg
set wildignore+=*/.DS_Store,*/tmp/*

" https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
set spelllang=en_us
set spellfile=~/.vim/spell/en.utf-8.add
if has('syntax')
  set spellcapcheck=                  " don't check for capital letters at start of sentence
endif

set complete+=kspell

" Disable unsafe commands.
" Only run autocommands owned by me
" http://andrew.stwrt.ca/posts/project-specific-vimrc/
set secure
" set exrc   " Enable use of directory-specific .vimrc

if has('virtualedit')
  set virtualedit=block               " allow cursor to move where there is no text in visual block mode
endif
set whichwrap=b,h,l,s,<,>,[,],~       " allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries

set completeopt+=menuone
set completeopt-=preview

" highlight current line (Check auto groups too)
" https://github.com/mhinz/vim-galore#smarter-cursorline
set cursorline
set nocursorcolumn       " do not highlight column
autocmd InsertLeave,WinEnter * set cursorline
autocmd InsertEnter,WinLeave * set nocursorline

set lazyredraw                        " don't bother updating screen during macro playback

" highlight matching [{()}]
set showmatch
set title

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

" reload files when changed on disk, i.e. via `git checkout`
set autoread

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


if has('windows')
  set fillchars=diff:⣿,vert:┃              " BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
endif

if has('linebreak')
  set linebreak
  let &showbreak='↳ '                 " DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)
  set breakindent                     " indent wrapped lines to match start
  if exists('&breakindentopt')
    set breakindentopt=shift:2        " emphasize broken lines by indenting them
  endif
endif


if exists('&belloff')
  set belloff=all                     " never ring the bell for any reason
endif

" show where you are
set ruler

set smartindent

set hidden

" Make tilde command behave like an operator.
set tildeop

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
  let g:terminal_color_0 = "#282828"
  let g:terminal_color_8 = "#928374"

  " neurtral_red + bright_red
  let g:terminal_color_1 = "#cc241d"
  let g:terminal_color_9 = "#fb4934"

  " neutral_green + bright_green
  let g:terminal_color_2 = "#98971a"
  let g:terminal_color_10 = "#b8bb26"

  " neutral_yellow + bright_yellow
  let g:terminal_color_3 = "#d79921"
  let g:terminal_color_11 = "#fabd2f"

  " neutral_blue + bright_blue
  let g:terminal_color_4 = "#458588"
  let g:terminal_color_12 = "#83a598"

  " neutral_purple + bright_purple
  let g:terminal_color_5 = "#b16286"
  let g:terminal_color_13 = "#d3869b"

  " neutral_aqua + faded_aqua
  let g:terminal_color_6 = "#689d6a"
  let g:terminal_color_14 = "#8ec07c"

  " light4 + light1
  let g:terminal_color_7 = "#a89984"
  let g:terminal_color_15 = "#ebdbb2"
endif

if has('nvim')
  let g:python_host_prog = '/usr/local/bin/python'
  let g:python3_host_prog = '/usr/local/bin/python3'
endif

" Configure fold status text
if has("folding")
  highlight Folded ctermbg=254

  function! NeatFoldText()
    let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
    let lines_count = v:foldend - v:foldstart + 1
    let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
    let foldchar = matchstr(&fillchars, 'fold:\zs.')
    let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
    let foldtextend = lines_count_text . repeat(foldchar, 8)
    let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
    return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
  endfunction
  set foldtext=NeatFoldText()

  set foldmethod=indent               " not as cool as syntax, but faster
  set foldlevelstart=99               " start unfolded
endif

if has('mksession')
  set viewdir=~/.vim/tmp/view       " override ~/.vim/view default
  set viewoptions=cursor,folds        " save/restore just these (with `:{mk,load}view`)
endif

if exists('$SUDO_USER')
  set nobackup                        " don't create root-owned files
  set nowritebackup                   " don't create root-owned files
else
  set backupdir=~/.vim/tmp/backup    " keep backup files out of the way
  set backupdir+=.
endif

if exists('$SUDO_USER')
  set noswapfile                      " don't create root-owned files
else
  set directory=~/.vim/tmp/swap//    " keep swap files out of the way
  set directory+=.
endif

set updatecount=80                    " update swapfiles every 80 typed chars

if has('persistent_undo')
  if exists('$SUDO_USER')
    set noundofile                    " don't create root-owned files
  else
    set undodir=~/.vim/tmp/undo       " keep undo files out of the way
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
    set shada='1000,<500,:500,/500,n~/.vim/tmp/main.shada
    autocmd CursorHold,FocusGained,FocusLost * rshada|wshada
  else
    set viminfo='1000,<500,:500,/500,n~/.vim/tmp/viminfo
  endif
endif

if has('nvim')
  set inccommand=nosplit                " incremental command live feedback"
endif
