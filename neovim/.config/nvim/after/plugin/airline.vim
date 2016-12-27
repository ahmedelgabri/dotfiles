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

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_mode_map = {
      \'__' : '-',
      \ 'n'  : 'N',
      \'no' : 'N·Operator Pending',
      \'v'  : 'V',
      \'V'  : 'V·Line',
      \'' : 'V·Block',
      \'s'  : 'Select',
      \'S'  : 'S·Line',
      \'' : 'S·Block',
      \'i'  : 'I',
      \'R'  : 'R',
      \'Rv' : 'V·Replace',
      \'c'  : 'Command',
      \'cv' : 'Vim Ex',
      \'ce' : 'Ex',
      \'r'  : 'Prompt',
      \'rm' : 'More',
      \'r?' : 'Confirm',
      \'!'  : 'Shell',
      \'t'  : 'Terminal'
      \}
let g:airline_powerline_fonts = 1
let g:airline_detect_paste = 1
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.branch = ''
let g:airline_symbols.maxlinenr = '☰'
let g:airline_detect_modified=1
let g:airline_inactive_collapse=1
let g:airline_skip_empty_sections = 1
let g:airline#extensions#default#layout = [
      \ [ 'a', 'b', 'c' ],
      \ [ 'error', 'warning', 'x', 'y', 'z' ]
      \ ]

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#wordcount#enabled = 1
let g:airline#extensions#whitespace#enabled = 1
let g:airline#extensions#neomake#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline#extensions#obsession#enabled = 1

function! AirlineInit()
  call airline#parts#define_raw('modified', '%{&modified ? " •" : ""}')
  call airline#parts#define_accent('modified', 'red')
  let g:airline_section_c = airline#section#create(['%f', 'modified'])

  let g:airline_section_x = airline#section#create(['%{gutentags#statusline("[Generating\ tags...]")} %{FileSize()}', get(g:, 'airline_section_x', g:airline_section_x)])
endfunction

call airline#parts#define_accent('mode', 'none')
" call airline#parts#define_accent('maxlinenr', 'none')

autocmd User AirlineAfterInit call AirlineInit()
