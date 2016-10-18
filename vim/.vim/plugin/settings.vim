set showtabline=2
set laststatus=2
set tabline="%1T"


if !has('nvim')
  set nocompatible
  set encoding=utf-8
  set autoindent
  " Fix broken backspace in some setups
  set backspace=2
  " Display as much as possibe of a window's last line.
  set display+=lastline
  set laststatus=2
  set ttyfast
  set wildmenu
endif

if has('nvim')
  set shada='1000,<500,:500,/500,n~/Box\ Sync/dotfiles/vim/main.shada
  autocmd CursorHold,FocusGained,FocusLost * rshada|wshada

  let g:python2_host_prog = '/usr/local/bin/python'
  let g:python3_host_prog = '/usr/local/bin/python3'
else
  set viminfo='1000,<500,:500,/500,n~/.viminfo
endif

" number of visual spaces per TAB
set tabstop=2
" insert mode tab and backspace, number of spaces in tab when editing
set softtabstop=2
set expandtab
" normal mode indentation commands use 2 spaces
set shiftwidth=2
set shiftround

set nowrap

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
silent! match OverLength /\%>120v.\+/
" function! ToggleTextLimit()
"   if &colorcolumn == '120'
"     let &colorcolumn='+' . join(range(0, 254), ',+')
"   else
"     set textwidth=120
"     set colorcolumn=120
"   endif
" endfunction
" autocmd InsertEnter,InsertLeave * call ToggleTextLimit()
" autocmd InsertEnter,InsertLeave * silent! match OverLength /\%>120v.\+/
" autocmd FileType help,qf setl colorcolumn=

syntax sync minlines=256 " start highlighting from 256 lines backwards
set synmaxcol=300        " do not highlith very long lines
" set re=1                 " use explicit old regexpengine, seems to be more faster

" show line numbers, hybrid. Relative with absolute for the line you are on.
set number relativenumber

" show command in bottom bar
set showcmd

" Don't Display the mode you're in. since it's already shown on the statusline
set noshowmode

" show a navigable menu for tab completion
set wildmode=longest,list,full
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem,*.pyc
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*
set wildignore+=*/tmp/librarian/*,*/.vagrant/*,*/.kitchen/*,*/vendor/cookbooks/*
set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*
set wildignore+=*.swp,*~,._*,*.jpg,*.png,*.gif,*.jpeg
set wildignore+=*/.DS_Store,*/tmp/*

" https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
set spelllang=en_us
set spellfile=$HOME/Box\ Sync/dotfiles/vim/en.utf-8.add
if has('syntax')
  set spellcapcheck=                  " don't check for capital letters at start of sentence
endif
set complete+=kspell
" Disable unsafe commands.
" http://andrew.stwrt.ca/posts/project-specific-vimrc/
set secure

if has('virtualedit')
  set virtualedit=block               " allow cursor to move where there is no text in visual block mode
endif
set whichwrap=b,h,l,s,<,>,[,],~       " allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries
set completeopt+=menuone
set completeopt-=preview

" highlight current line (Check auto groups too)
" https://github.com/mhinz/vim-galore#smarter-cursorline
autocmd InsertLeave,WinEnter * set cursorline
autocmd InsertEnter,WinLeave * set nocursorline
set nocursorcolumn       " do not highlight column

" redraw only when we need to.
set lazyredraw

" highlight matching [{()}]
set showmatch
set title

" More natural splitting
set splitbelow
set splitright

" Search
"-----------------
" Ignore case in search.
set ignorecase smartcase

if has('persistent_undo')
  set undofile                          " Save undos after file closes
  set undodir=~/.config/nvim/undodir    " Save undos in undodir within nvim dir
endif

" fix slight delay after pressing ESC then O http://ksjoberg.com/vim-esckeys.html
" set timeout timeoutlen=500 ttimeoutlen=100
set timeoutlen=1000 ttimeoutlen=0

" nofold
set nofoldenable

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j                " remove comment leader when joining comment lines
endif

set formatoptions+=n                  " smart auto-indenting inside numbered lists

" No beeping.
set visualbell

set linebreak

" No flashing.
set noerrorbells

" reload files when changed on disk, i.e. via `git checkout`
set autoread

" Start scrolling slightly before the cursor reaches an edge
set scrolloff=5
set sidescrolloff=5

" Scroll sideways a character at a time, rather than a screen at a time
set sidescroll=1

" yank and paste with the system clipboard
set clipboard=unnamed

" show trailing whitespace
set list
set listchars=tab:▸\ ,trail:•,nbsp:_,eol:¬,precedes:«,extends:»,nbsp:░
set showbreak=↪
set fillchars=diff:⣿,vert:│

if has('linebreak')
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

set noswapfile

set hidden

set formatoptions+=rn1

" No backups.
set nobackup
set nowritebackup
set noswapfile

" Make tilde command behave like an operator.
set tildeop

" Avoid unnecessary hit-enter prompts.
set shortmess+=atI

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

set fdm=indent

highlight Folded ctermbg=254

" Configure fold status text
if has("folding")
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
endif


if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor\ --vimgrep
endif

