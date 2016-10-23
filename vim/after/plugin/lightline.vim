function! FileSize()
  let bytes = getfsize(expand('%:p'))
  if (bytes >= 1024)
    let kbytes = bytes / 1024
  endif
  if (exists('kbytes') && kbytes >= 1000)
    let mbytes = kbytes / 1000
  endif

  if bytes <= 0
    return '[empty file] '
  endif

  if (exists('mbytes'))
    return mbytes . 'MB '
  elseif (exists('kbytes'))
    return kbytes . 'KB '
  else
    return bytes . 'B '
  endif
endfunction

function! ReadOnly()
  if &readonly || !&modifiable
    return ''
  else
    return ''
endfunction

function! Modified()
  if &filetype == "help"
    return ""
  elseif &modified
    return "+"
  elseif &modifiable
    return ""
  else
    return ""
  endif
endfunction

function! GitInfo()
  let git = fugitive#head()
  if git != ''
    return ' '.fugitive#head()
  else
    return ''
endfunction

function! Filename()
  return ('' != ReadOnly() ? ReadOnly() . ' ' : '') .
       \ expand('%') =~? 'term://.*\.fzf/bin/fzf' ? '' :
       \ ('' != expand('%:p:~') ? expand('%:p:~') : '[No Name]') .
       \ ('' != Modified() ? ' ' . Modified() : '')
endfunction

function! LightlineNeomake()
    return '%{neomake#statusline#LoclistStatus()}'
endfunction

function! LightlineTags()
    return winwidth(0) > 120 ? '%{gutentags#statusline("[Generating\ tags...]")}' : ''
endfunction

function! LightlineObsession()
    return '%{ObsessionStatus()}'
endfunction

let g:lightline = {
\ 'enable' :{
\   'tabline': 0,
\   'statusline': 1
\ },
\ 'colorscheme': 'onedark',
\ 'separator': {
\   'left': '',
\   'right': ''
\ },
\ 'subseparator': {
\   'left': '',
\   'right': ''
\ },
\ 'mode_map': {
\   '__' : '-',
\   'n'  : 'N',
\   'no' : 'N·Operator Pending',
\   'v'  : 'V',
\   'V'  : 'V·Line',
\   '' : 'V·Block',
\   's'  : 'Select',
\   'S'  : 'S·Line',
\   '' : 'S·Block',
\   'i'  : 'I',
\   'R'  : 'R',
\   'Rv' : 'V·Replace',
\   'c'  : 'Command',
\   'cv' : 'Vim Ex',
\   'ce' : 'Ex',
\   'r'  : 'Prompt',
\   'rm' : 'More',
\   'r?' : 'Confirm',
\   '!'  : 'Shell',
\   't'  : 'Terminal'
\ },
\ 'active': {
\   'left': [ [ 'mode' ], [ 'spell', 'paste' ], ['fugitive'], ['filename'] ],
\   'right': [ ['percent', 'lineinfo'], ['fileformat', 'fileencoding', 'filetype', 'filesize'], ['neomake', 'obsession'], ['tags'] ]
\ },
\ 'component': {
\   'filename': '%<%f'
\ },
\ 'component_function': {
\   'readonly': 'ReadOnly',
\   'modified': 'Modified',
\   'fugitive': 'GitInfo',
\   'filesize': 'FileSize'
\ },
\ 'component_expand': {
\   'neomake': 'LightlineNeomake',
\   'tags': 'LightlineTags',
\   'obsession': 'LightlineObsession'
\ },
\ 'component_type': {
\   'paste': 'warning',
\   'spell': 'warning',
\   'neomake': 'error',
\ },
\ }

