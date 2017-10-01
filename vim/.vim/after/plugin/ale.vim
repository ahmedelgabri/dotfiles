scriptencoding utf-8

if !exists(':ALEInfo')
  finish
endif

let g:ale_fix_on_save = 1
let g:ale_sign_error = '✖'
let g:ale_sign_warning = '⚠'
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_format = '[%linter%] %s'

" If local config file is availabe use it, otherwise use custom config
if !empty(glob(getcwd() .'/.prettierrc')) || !empty(glob(getcwd() .'/prettier.config.js'))
  let g:ale_javascript_prettier_use_local_config = 1
else
  let s:PARSER = empty(glob(getcwd() .'/.flowconfig')) ?  'babylon' : 'flow'
  let g:ale_javascript_prettier_options = '--parser ' . s:PARSER . ' --single-quote --trailing-comma all --no-semi'
endif

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
