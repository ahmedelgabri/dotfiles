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
let g:ale_javascript_prettier_options = '--single-quote --trailing-comma all --no-semi --config-precedence prefer-file'

" Don't auto fix (format) files inside `node_modules`, `forks` directory or minified files, or jquery files :shrug:
let g:ale_linter_aliases = {
      \ 'mail': 'markdown'
      \}

let g:ale_linters = {
      \ 'javascript': ['eslint', 'flow'],
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
      \   'reason': [
      \       'refmt',
      \   ],
      \}

" Don't auto fix (format) files inside `node_modules`, `forks` directory or minified files
if (!empty(matchstr(expand('%:p'), '\(node_modules\|\.min\.\(js\|css\)$|jquery.*\)')))
  let b:ale_enabled = 0
  let b:ale_fix_on_save = 0
endif

if (!empty(matchstr(expand('%:p'), 'Sites/forks')))
  let b:ale_fix_on_save = 0
endif

" This is not working properly right now: see https://github.com/w0rp/ale/issues/1095
" let g:ale_pattern_options = {
"       \   '\.min\.(js\|css)$': {
"       \       'ale_enabled': 0,
"       \       'ale_fixers': { 'javascript': [], 'javascript.jsx': [], 'css': [] },
"       \   },
"       \   'jquery.*': {
"       \       'ale_enabled': 0,
"       \       'ale_fixers': { 'javascript': [], 'javascript.jsx': [] },
"       \   },
"       \   'node_modules/.*': {
"       \       'ale_enabled': 0,
"       \       'ale_fixers': { 'javascript': [], 'javascript.jsx': [], 'css': [], 'scss': [] },
"       \   },
"       \   'Sites/forks/.*': {
"       \       'ale_fixers': { 'javascript': [], 'javascript.jsx': [], 'css': [], 'scss': [] },
"       \   },
"       \}

