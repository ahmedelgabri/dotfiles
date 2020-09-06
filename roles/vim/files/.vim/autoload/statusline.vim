scriptencoding utf-8

"display lineNoIndicator (from drzel/vim-line-no-indicator)
function! statusline#lineNoIndicator() abort
  let l:line_no_indicator_chars = ['⎺', '⎻', '─', '⎼', '⎽']

  let l:current_line = line('.') - 1
  let l:total_lines = line('$') - 1

  if l:current_line == 0
    let l:index = 0
  elseif l:current_line == l:total_lines
    let l:index = -1
  else
    let l:line_no_fraction = floor(l:current_line) / floor(l:total_lines)
    let l:index = float2nr(l:line_no_fraction * len(l:line_no_indicator_chars))
  endif

  return l:line_no_indicator_chars[l:index]
endfunction

function! statusline#rhs() abort
  return winwidth(0) > 80 ? printf('%s %02d/%02d:%02d', statusline#lineNoIndicator(), line('.'), line('$'), col('.')) : statusline#lineNoIndicator()
endfunction

function! statusline#getDiffColors() abort
  return ['%#DiffDelete#', '%#DiffChange#', '%#DiffAdd#', '%#DiffText#']
endfunction

function! statusline#gitInfo() abort
  if !exists('*fugitive#head')
    return ''
  endif

  let l:out = fugitive#head(10)
  if !empty(l:out)
    let l:out = utils#GetIcon('branch') . ' ' . l:out
  endif
  return l:out
endfunction

function! statusline#readOnly() abort
  if !&modifiable && &readonly
    return utils#GetIcon('lock') . ' RO'
  elseif &modifiable && &readonly
    return 'RO'
  elseif !&modifiable && !&readonly
    return utils#GetIcon('lock')
  else
    return ''
  endif
endfunction

function! statusline#filepath() abort
  let l:filename = expand('%:~:.:t')
  let l:base = expand('%:~:.:h')
  let l:prefix = empty(l:base) || l:base ==# '.' ? '' : l:base.'/'
  let [l:DELETE, l:CHANGE, l:ADD, l:TEXT] = statusline#getDiffColors()

  if isdirectory(expand('%'))
    return '%4* Dirvish %*'
  elseif empty(l:prefix) && empty(l:filename)
    return printf('%%4*%%f%%*%s%%*', &modified ? l:CHANGE . '-' . '%*' : '%4*')
  else
    return printf('%%4*%s%%*%s%s%%*', l:prefix, &modified ? l:CHANGE : '%6*', l:filename)
  endif
endfunction

" :h mode() to see all modes
let s:dictmode={
      \'no'     : 'N-Operator Pending',
      \'v'      : 'V.',
      \'V'      : 'V·Line',
      \"\<C-V>" : 'V·Block',
      \'s'      : 'S.',
      \'S'      : 'S·Line',
      \"\<C-S>" : 'S·Block.',
      \'i'      : 'I.',
      \'ic'     : 'I·Compl',
      \'ix'     : 'I·X-Compl',
      \'R'      : 'R.',
      \'Rc'     : 'Compl·Replace',
      \'Rx'     : 'V·Replace',
      \'Rv'     : 'X-Compl·Replace',
      \'c'      : 'Command',
      \'cv'     : 'Vim Ex',
      \'ce'     : 'Ex',
      \'r'      : 'Propmt',
      \'rm'     : 'More',
      \'r?'     : 'Confirm',
      \'!'      : 'Sh',
      \'t'      : 'T.',
      \}

exec printf('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Identifier', 'fg', 'gui'), utils#get_color('Identifier', 'fg', 'cterm'))

function! statusline#getMode() abort
  return get(s:dictmode, mode(), mode() ==# 'n' ? '' : mode().' NOT IN MAP')
endfunction
