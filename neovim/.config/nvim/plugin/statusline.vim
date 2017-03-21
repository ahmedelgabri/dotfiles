set showtabline=2
set laststatus=2
set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE FUNCTIONS
" ALL STATUS LINE FUNCTIONS REQUIRE SOURCE CODE PRO
" OR A FONT WITH SIMILAR UNICODE SUPPORT
"------------------------------------------------------------------------------
" https://gabri.me/blog/diy-vim-statusline
" USE FUGITIVE.VIM TO RETURN THE GIT HEAD INFORMATION
function! GitInfo()
  let l:gitbranch = fugitive#head()
  if l:gitbranch != ''
    return '⎇ ' .fugitive#head()
  else
    return '⎇ '
endfunction

" SET A LOCK IF THE DOCUMENT IS READ ONLY AND NOT MODIFIABLE
function! ReadOnly()
  if !&modifiable && &readonly
    return ' RO'
  elseif &modifiable && &readonly
    return 'RO'
  elseif !&modifiable && !&readonly
    return ''
  else
    return ''
endfunction

" SET SYMBOLS IF DOCUMENT HAS BEEM MODIFIED (○○) OR NOT MODIFIED (●●)
function! Modified()
  if &modified
    return ' •'
  else
    return ''
endfunction

" GET THE FILE SIZE OF THE CURRENT FILE
function! GetFileSize()
  let l:bytes = getfsize(expand(@%))
  if l:bytes >= 1024
    let l:kbytes = l:bytes / 1024
  endif
  if l:bytes <= 0
    return '[empty file]'
  endif
  if (exists('l:kbytes'))
    return l:kbytes . 'KB'
  else
    return l:bytes . 'B'
  endif
endfunction

" DEFINE MODE DICTIONARY
let g:dictmode= {'n': ['N', 'green'],
                \ 'no': ['N-Operator Pending', 'green'],
                \ 'v': ['V', 'purple'],
                \ 'V': ['V·Line', 'purple'],
                \ '': ['V·Block', 'purple'],
                \ 's': ['Select', 'yellow'],
                \ 'S': ['S·Line', 'yellow'],
                \ '^S': ['S·Block', 'yellow'],
                \ 'i': ['I', 'blue'],
                \ 'R': ['R', 'red'],
                \ 'Rv': ['V·Replace', 'red'],
                \ 'c': ['Command', 'orange'],
                \ 'cv': ['Vim Ex', 'brown'],
                \ 'ce': ['Ex', 'brown'],
                \ 'r': ['Propmt', 'brown'],
                \ 'rm': ['More', 'brown'],
                \ 'r?': ['Confirm', 'brown'],
                \ '!': ['Shell', 'orange'],
                \ 't': ['Terminal', 'orange']}

" DEFINE COLORS FOR STATUSBAR
let g:dictstatuscolor={'red': 'hi StatusLine guifg=#ab4642',
                        \ 'orange': 'hi StatusLine guifg=#dc9656',
                        \ 'yellow': 'hi StatusLine guifg=#f7ca88',
                        \ 'green': 'hi StatusLine guifg=#a1b56c',
                        \ 'blue': 'hi StatusLine guifg=#7cafc2',
                        \ 'purple': 'hi StatusLine guifg=#ba8baf',
                        \ 'brown': 'hi StatusLine guifg=#a16946',}

" GET CURRENT MODE FROM DICTIONARY AND RETURN IT
" IF MODE IS NOT IN DICTIONARY RETURN THE ABBREVIATION
" GetMode() GETS THE MODE FROM THE ARRAY THEN RETURNS THE NAME
function! GetMode()
  let l:modenow = mode()
  let l:modelist = get(g:dictmode, l:modenow, [l:modenow, 'red'])
  let l:modecolor = l:modelist[1]
  let l:modename = l:modelist[0]
  let l:modeexe = get(g:dictstatuscolor, l:modecolor, 'red')
    exec l:modeexe
    return l:modename
endfunction

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------
set laststatus=2    " LAST WINDOW WILL ALWAYS HAVE A STATUS LINE
set noruler         " HIDES RULER

" STATUS LINE
" set statusline=                     " MAKE IT SO EVERY STATUSLINE IS +=
" set statusline+=%{Modified()}       " CHECK MODIFIED STATUS
" set statusline+=%{GetMode()}        " GET CURRENT MODE
" set statusline+=[%{ReadOnly()}]     " CHECK READ ONLY AND MODIFIABLE STATUS
" set statusline+=%{%{gita#statusline#preset("status")}}   " GIT BRANCH INFORMATION
" set statusline+=▪%.25F              " PATH TO THE FILE
" set statusline+=%=                  " SWITCH TO RIGHT SIDE OF STATUS LINE
" set statusline+=▪                   " SQUARE SEPARATOR
" set statusline+=%{GetFileSize()}    " GET SIZE OF FILE
" set statusline+=%y                  " TYPE OF THE FILE IN BUFFER
" set statusline+=▪                   " SQUARE SEPARATOR
" set statusline+=%{&ff}              " FORMAT OF THE FILE
" set statusline+=‖                   " COLUMN SEPARATOR
" set statusline+=%02v                " CURRENT COLUMN - 00
" set statusline+=‖☰\                 " COLUMN SEPARATOR
" set statusline+=%03l                " CURRENT LINE - 000
" set statusline+=/                   " SEPARATOR
" set statusline+=%03L                " TOTAL LINES - 000
" set statusline+=▪                   " SQUARE SEPARATOR
" set statusline+=%P                  " PERCENTAGE THROUGH BUFFER

set statusline=
" set statusline+=%{ChangeStatuslineColor()}               " Changing the statusline color
set statusline+=%0*\ %{GetMode()}                        " Current mode
set statusline+=%*
" set statusline+=%8*\ %3{[%n]}                                " buffernr
set statusline+=%{gita#statusline#preset('status')}   " GIT BRANCH INFORMATION
set statusline+=%8*\ %<%F\ %{ReadOnly()}\ %m\ %w\        " File+path
set statusline+=%{Modified()}
" set statusline+=%{SyntasticStatuslineFlag()}             " Syntastic errors
set statusline+=%*
set statusline+=%9*\ %=                                  " Space
set statusline+=%#warningmsg#
set statusline+=%8*\ %{GetFileSize()}                 " File size
set statusline+=%8*\ %y\                                 " FileType
set statusline+=%7*\ %{(&fenc!=''?&fenc:&enc)}\[%{&ff}]
set statusline+=%0*\ %3p%%\ <U+E0A1>\ %l:\ %3c\                 " Rownumber/total (%)

