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
function! statusline#ALEGetOk()
  let l:res = ale#statusline#Status()
  if l:res ==# 'OK'
    return '•'
  else
    return ''
  endif
endfunction

function! statusline#ALEGetError()
  let l:res = ale#statusline#Status()
  if l:res ==# 'OK'
    return ''
  else
    let l:e_w = split(l:res)
    if len(l:e_w) == 2 || match(l:e_w, 'E') > -1
      return '•' . matchstr(l:e_w[0], '\d\+')
    else
      return ''
    endif
  endif
endfunction

function! statusline#ALEGetWarning()
  let l:res = ale#statusline#Status()
  if l:res ==# 'OK'
    return ''
  else
    let l:e_w = split(l:res)
    if len(l:e_w) == 2
      return '•' . matchstr(l:e_w[1], '\d\+')
    elseif match(l:e_w, 'W') > -1
      return '•' . matchstr(l:e_w[0], '\d\+')
    else
      return ''
    endif
  endif
endfunction

" Modified from here
" https://github.com/mhinz/vim-signify/blob/748cb0ddab1b7e64bb81165c733a7b752b3d36e4/doc/signify.txt#L565-L582
function! statusline#GetHunks(plugin)
  let l:symbols = ['+', '-', '~']
  let [l:added, l:modified, l:removed] = a:plugin
  let l:stats = [l:added, l:removed, l:modified]  " reorder
  let l:hunkline = ''

  for l:i in range(3)
    if l:stats[l:i] > 0
      let l:hunkline .= printf('%s%s ', l:symbols[l:i], l:stats[l:i])
    endif
  endfor

  if !empty(l:hunkline)
    let l:hunkline = printf('[%s]', l:hunkline[:-2])
  endif

  return l:hunkline
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


function! statusline#gitInfo(plugin)
  let l:gitbranch = a:plugin
  if l:gitbranch !=# ''
    return '⎇ ' .l:gitbranch
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
    return '●'
  else
    return ''
  endif
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

