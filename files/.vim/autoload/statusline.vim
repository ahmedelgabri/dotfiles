scriptencoding utf-8

function! statusline#rhs() abort
  return winwidth(0) > 80 ? printf('%02d/%02d:%02d', line('.'), line('$'), col('.')) : ''
endfunction

function! statusline#fileSize() abort
  let l:size = getfsize(expand('%'))
  if l:size == 0 || l:size == -1 || l:size == -2
    return ''
  endif
  if l:size < 1024
    return l:size.' bytes'
  elseif l:size < 1024*1024
    return printf('%.1f', l:size/1024.0).'k'
  elseif l:size < 1024*1024*1024
    return printf('%.1f', l:size/1024.0/1024.0) . 'm'
  else
    return printf('%.1f', l:size/1024.0/1024.0/1024.0) . 'g'
  endif
endfunction

function! statusline#getDiffColors() abort
  return ['%#DiffDelete#', '%#DiffChange#', '%#DiffAdd#']
endfunction

" For a more fancy ale statusline
" https://github.com/w0rp/ale#5iv-how-can-i-show-errors-or-warnings-in-my-statusline
function! statusline#LinterStatus() abort
  if !exists(':ALEInfo')
    return ''
  endif

  let l:error_symbol = functions#GetIcon('linter_error')
  let l:style_symbol = functions#GetIcon('linter_style')
  let l:counts = ale#statusline#Count(bufnr(''))
  let [l:DELETE, l:CHANGE, l:ADD] = statusline#getDiffColors()
  let l:status = []

  if l:counts.error
    call add(l:status, printf('%s%d %s %%*', l:DELETE,  l:counts.error, l:error_symbol))
  endif
  if l:counts.warning
    call add(l:status, printf('%s%d %s %%*', l:CHANGE, l:counts.warning, l:error_symbol))
  endif
  if l:counts.style_error
    call add(l:status, printf('%s%d %s %%*', l:DELETE, l:counts.style_error, l:style_symbol))
  endif
  if l:counts.style_warning
    call add(l:status, printf('%s%d %s %%*', l:CHANGE, l:counts.style_warning, l:style_symbol))
  endif

  return join(l:status, ' ')
endfunction

function! statusline#statusDiagnostic() abort
  if exists('*LanguageClient#statusLine')
    return LanguageClient#statusLine()
  endif

  let l:info = get(b:, 'coc_diagnostic_info', {})
  if empty(l:info)
    return ''
  endif

  let [l:DELETE, l:CHANGE, l:ADD] = statusline#getDiffColors()
  let l:msgs = []
  if get(l:info, 'error', 0)
    call add(l:msgs, printf('%s%d %s %%*', l:DELETE,  l:info['error'] , functions#GetIcon('linter_error')))
  endif
  if get(info, 'warning', 0)
    call add(l:msgs, printf('%s%d %s %%*', l:DELETE,  l:info['warning'] , functions#GetIcon('linter_style')))
  endif

  return join(l:msgs, ' ')
endfunction

function! statusline#gitInfo() abort
  if !exists('*fugitive#head')
    return ''
  endif

  let l:out = fugitive#head(10)
  if !empty(l:out)
    let l:out = functions#GetIcon('branch') . l:out
  endif
  return l:out
endfunction

function! statusline#readOnly() abort
  if !&modifiable && &readonly
    return functions#GetIcon('lock') . ' RO'
  elseif &modifiable && &readonly
    return 'RO'
  elseif !&modifiable && !&readonly
    return functions#GetIcon('lock')
  else
    return ''
  endif
endfunction

function! statusline#filepath() abort
  let l:basename = expand('%:h')
  let l:filename = expand('%:t')
  let l:extension = expand('%:e')
  let l:prefix = (l:basename ==# '' || l:basename ==# '.') ?
        \ '' : substitute(l:basename . '/', '\C^' . $HOME, '~', '')
  let l:diffColors = statusline#getDiffColors()

  if empty(l:prefix) && empty(l:filename)
    return printf('%%4* %%f%%* %s%%m%%*', l:diffColors[2])
  else
    return printf('%%4* %s%%*%s%s%%*', l:prefix, &modified ? l:diffColors[2] : '%6*', l:filename)
  endif
endfunction

" DEFINE MODE DICTIONARY
" :h mode() to see all modes
let s:dictmode= {
      \ 'no'     : ['N-Operator Pending' , '4'],
      \ 'v'      : ['V.'                 , '6'],
      \ 'V'      : ['V·Line'             , '6'],
      \ "\<C-V>" : ['V·Block'            , '6'],
      \ 's'      : ['S.'                 , '3'],
      \ 'S'      : ['S·Line'             , '3'],
      \ "\<C-S>" : ['S·Block.'           , '3'],
      \ 'i'      : ['I.'                 , '5'],
      \ 'ic'     : ['I·Compl'            , '5'],
      \ 'ix'     : ['I·X-Compl'          , '5'],
      \ 'R'      : ['R.'                 , '1'],
      \ 'Rc'     : ['Compl·Replace'      , '1'],
      \ 'Rx'     : ['V·Replace'          , '1'],
      \ 'Rv'     : ['X-Compl·Replace'    , '1'],
      \ 'c'      : ['Command'            , '2'],
      \ 'cv'     : ['Vim Ex'             , '7'],
      \ 'ce'     : ['Ex'                 , '7'],
      \ 'r'      : ['Propmt'             , '7'],
      \ 'rm'     : ['More'               , '7'],
      \ 'r?'     : ['Confirm'            , '7'],
      \ '!'      : ['Sh'                 , '2'],
      \ 't'      : ['T.'                 , '2']
      \ }

" DEFINE COLORS FOR STATUSBAR
let s:statusline_color=printf('highlight! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('Identifier'),'fg', 'gui'), synIDattr(hlID('Identifier'),'fg', 'cterm'))
let s:dictstatuscolor={
      \ '1': s:statusline_color,
      \ '2': s:statusline_color,
      \ '3': s:statusline_color,
      \ '4': s:statusline_color,
      \ '5': s:statusline_color,
      \ '6': s:statusline_color,
      \ '7': s:statusline_color,
      \}


" GET CURRENT MODE FROM DICTIONARY AND RETURN IT
" IF MODE IS NOT IN DICTIONARY RETURN THE ABBREVIATION
" GetMode() GETS THE MODE FROM THE ARRAY THEN RETURNS THE NAME
function! statusline#getMode() abort
  let l:modenow = mode()
  if has_key(s:dictmode, l:modenow)
    let l:modelist = get(s:dictmode, l:modenow, [l:modenow, '1'])
    let l:modecolor = l:modelist[1]
    let l:modename = l:modelist[0]
    let l:modehighlight = get(s:dictstatuscolor, l:modecolor, '1')
    exec l:modehighlight
    return l:modename
  endif
  return ''
endfunction
