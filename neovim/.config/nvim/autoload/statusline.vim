scriptencoding utf-8

function! statusline#rhs() abort
  let l:rhs=' '
  if winwidth(0) > 80
    let l:column=virtcol('.')
    let l:width=virtcol('$')
    let l:line=line('.')
    let l:height=line('$')

    " Add padding to stop rhs from changing too much as we move the cursor.
    let l:padding=len(l:height) - len(l:line)
    if (l:padding)
      let l:rhs.=repeat(' ', l:padding)
    endif

    let l:rhs.='␤ '
    let l:rhs.=l:line
    let l:rhs.='/'
    let l:rhs.=l:height
    let l:rhs.=' ¶ '
    let l:rhs.=l:column
    let l:rhs.='/'
    let l:rhs.=l:width
    let l:rhs.=' '

    " Add padding to stop rhs from changing too much as we move the cursor.
    if len(l:column) < 2
      let l:rhs.=' '
    endif
    if len(l:width) < 2
      let l:rhs.=' '
    endif
  endif
  return l:rhs
endfunction

function! statusline#getAleStatus()
  if exists('*ALEGetStatusLine')
    let l:f = ALEGetStatusLine()
    if l:f =~ get(g:, 'ale_sign_error', g:ale_sign_error)
      echo 'ERROR'
    elseif l:f =~ get(g:, 'ale_sign_warning', g:ale_sign_warning)
      echo 'WARN'
    else
      echo l:f
    endif
  endif
endfunction

function! statusline#fileSize()
  let l:bytes = getfsize(expand('%:p'))
  if (l:bytes >= 1024)
    let l:kbytes = l:bytes / 1024
  endif
  if (exists('kbytes') && l:kbytes >= 1000)
    let l:mbytes = l:kbytes / 1000
  endif

  if l:bytes <= 0
    return '[empty file] '
  endif

  if (exists('mbytes'))
    return l:mbytes . 'MB '
  elseif (exists('kbytes'))
    return l:kbytes . 'KB '
  else
    return l:bytes . 'B '
  endif
endfunction


function! statusline#gitInfo()
  let l:gitbranch = fugitive#head()
  if l:gitbranch !=# ''
    return '⎇ ' .fugitive#head()
  else
    return '⎇ '
  endif
endfunction

function! statusline#readOnly()
  if !&modifiable && &readonly
    return ' RO'
  elseif &modifiable && &readonly
    return 'RO'
  elseif !&modifiable && !&readonly
    return ''
  else
    return ''
  endif
endfunction

function! statusline#modified()
  if &modified
    return ' •'
  else
    return ''
  endif
endfunction


" DEFINE MODE DICTIONARY
let s:dictmode= {'n': ['N', 'green'],
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
let s:dictstatuscolor={'red': 'hi StatusLine guifg=#ab4642',
      \ 'orange': 'hi StatusLine guifg=#dc9656',
      \ 'yellow': 'hi StatusLine guifg=#f7ca88',
      \ 'green': 'hi StatusLine guifg=#a1b56c',
      \ 'blue': 'hi StatusLine guifg=#7cafc2',
      \ 'purple': 'hi StatusLine guifg=#ba8baf',
      \ 'brown': 'hi StatusLine guifg=#a16946',}

" GET CURRENT MODE FROM DICTIONARY AND RETURN IT
" IF MODE IS NOT IN DICTIONARY RETURN THE ABBREVIATION
" GetMode() GETS THE MODE FROM THE ARRAY THEN RETURNS THE NAME
function! statusline#getMode()
  let l:modenow = mode()
  let l:modelist = get(s:dictmode, l:modenow, [l:modenow, 'red'])
  let l:modecolor = l:modelist[1]
  let l:modename = l:modelist[0]
  let l:modeexe = get(s:dictstatuscolor, l:modecolor, 'red')
  exec l:modeexe
  return l:modename
endfunction

function! statusline#fileprefix()
  let l:basename=expand('%:h')
  if l:basename == '' || l:basename == '.'
    return ''
  else
    " Make sure we show $HOME as ~.
    return substitute(l:basename . '/', '\C^' . $HOME, '~', '')
  endif
endfunction

