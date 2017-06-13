scriptencoding utf-8

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
let g:airline_detect_crypt=1
let g:airline_detect_spell=1
let g:airline_inactive_collapse=1
let g:airline_skip_empty_sections = 1
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.whitespace = 'Ξ'
let g:airline_detect_modified=1
let g:airline_inactive_collapse=1
let g:airline_skip_empty_sections = 1
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
let g:airline#extensions#default#layout = [
      \ [ 'a', 'b', 'c' ],
      \ [ 'x', 'y', 'error', 'warning' , 'z']
      \ ]

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#wordcount#enabled = 1
let g:airline#extensions#whitespace#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline#extensions#obsession#enabled = 1
let g:airline_exclude_filetypes = [
      \ 'GrepperSide'
      \ ]

call airline#parts#define_function('modified', 'statusline#modified')
call airline#parts#define_condition('modified', 'exists("*statusline#modified")')
call airline#parts#define_accent('modified', 'red')

call airline#parts#define_function('ALE', 'ALEGetStatusLine')
call airline#parts#define_condition('ALE', 'exists("*ALEGetStatusLine")')

call airline#parts#define_accent('mode', 'none')

function! AirlineInit()
  let g:airline_section_error = airline#section#create_right(['ALE'])
  let g:airline_section_warning = airline#section#create_right(['whitespace'])
  let g:airline_section_c = airline#section#create(['%f', 'modified'])
  let g:airline_section_z = airline#section#create(['obsession', '%{statusline#rhs()}'])
endfunction


autocmd User AirlineAfterInit call AirlineInit()
