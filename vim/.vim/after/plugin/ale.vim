scriptencoding utf-8

if !exists(':ALEInfo')
  finish
endif

let g:ale_fix_on_save = 1
let g:ale_sign_error = '●'
let g:ale_sign_warning = '●'
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_format = '[%linter%] %s'
let g:ale_javascript_prettier_use_local_config = 1

let s:flowconfig = findfile('.flowconfig', expand('%:p').';')
let s:PARSER = filereadable(s:flowconfig) ?  'flow' : 'babylon'
let g:ale_javascript_prettier_options = '--parser ' . s:PARSER . ' --single-quote --trailing-comma all --no-semi --config-precedence prefer-file'

let g:ale_linter_aliases = {'reason': 'ocaml'}

let g:ale_linters = {
      \ 'javascript': ['eslint', 'flow'],
      \ 'css': ['stylelint'],
      \ 'scss': ['stylelint'],
      \}

let g:ale_fixers = {
  \   'javascript': [
  \       'prettier',
  \   ],
  \   'css': [
  \       'prettier',
  \   ],
  \   'scss': [
  \       'prettier',
  \   ],
  \}
