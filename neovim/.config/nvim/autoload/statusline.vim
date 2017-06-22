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

" For a more fancy ale statusline
function! statusline#ALEGetStatus()
  let l:res = ale#statusline#Status()
  let l:e_w = split(l:res)
  let l:e_sign = get(g:, 'ale_sign_error', g:ale_sign_error)
  let l:w_sign = get(g:, 'ale_sign_warning', g:ale_sign_warning)
  " Not working, unicode issue?
  " echo index(l:e_w, l:e_sign)
  if index(l:e_w, l:w_sign) >= 0
    exec 'highlight ale_statusline guibg=orange guifg=black'
  elseif index(l:e_w, l:w_sign) < 0 && index(l:e_w, 'ok') < 0
    exec 'highlight ale_statusline guifg=black guibg=red'
  else
    exec 'highlight ale_statusline guifg=green guibg=None'
  endif
  return l:res . ' '
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
    return ''
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
    return '⎔'
  else
    return ''
  endif
endfunction


" DEFINE MODE DICTIONARY
let s:dictmode= {'n': ['N', '4'],
      \ 'no': ['N-Operator Pending', '4'],
      \ 'v': ['V', '6'],
      \ 'V': ['V·Line', '6'],
      \ '': ['V·Block', '6'],
      \ 's': ['Select', '3'],
      \ 'S': ['S·Line', '3'],
      \ '^S': ['S·Block', '3'],
      \ 'i': ['I', '5'],
      \ 'R': ['R', '1'],
      \ 'Rv': ['V·Replace', '1'],
      \ 'c': ['Command', '2'],
      \ 'cv': ['Vim Ex', '7'],
      \ 'ce': ['Ex', '7'],
      \ 'r': ['Propmt', '7'],
      \ 'rm': ['More', '7'],
      \ 'r?': ['Confirm', '7'],
      \ '!': ['Shell', '2'],
      \ 't': ['Terminal', '2']}

" DEFINE COLORS FOR STATUSBAR
let s:dictstatuscolor={
      \ '1': 'hi! StatusLine guibg=#ab4642 guifg=None',
      \ '2': 'hi! StatusLine guibg=#dc9656 guifg=None',
      \ '3': 'hi! StatusLine guibg=#f7ca88 guifg=None',
      \ '4': 'hi! StatusLine '.pinnacle#extract_highlight('Visual').' guifg=' .pinnacle#extract_fg('Normal'),
      \ '5': 'hi! StatusLine guibg='. pinnacle#extract_fg('Function') .' guifg=' .pinnacle#extract_fg('NonText') ,
      \ '6': 'hi! StatusLine guibg=#ba8baf guifg=None',
      \ '7': 'hi! StatusLine guibg=#a16946 guifg=None'
      \}

" GET CURRENT MODE FROM DICTIONARY AND RETURN IT
" IF MODE IS NOT IN DICTIONARY RETURN THE ABBREVIATION
" GetMode() GETS THE MODE FROM THE ARRAY THEN RETURNS THE NAME
function! statusline#getMode()
  let l:modenow = mode()
  let l:modelist = get(s:dictmode, l:modenow, [l:modenow, 'red'])
  let l:modecolor = l:modelist[1]
  let l:modename = l:modelist[0]
  let l:modeexe = get(s:dictstatuscolor, l:modecolor, 'red')
  " echo modeexe
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

