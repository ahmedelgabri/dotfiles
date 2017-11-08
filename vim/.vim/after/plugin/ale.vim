scriptencoding utf-8

if !exists(':ALEInfo')
  finish
endif

let g:ale_fix_on_save = 1

" Don't auto fix (format) files inside `node_modules`, `forks` directory or minified files
if (!empty(matchstr(expand('%:p'), '\(node_modules\|Sites/forks\|\.min\.\(js\|css\)$\)')))
  let b:ale_fix_on_save = 0
endif

let g:ale_sign_error = '●'
let g:ale_sign_warning = '●'
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_format = '[%linter%] %s'
let g:ale_javascript_prettier_options = '--single-quote --trailing-comma all --no-semi --config-precedence prefer-file'

let g:ale_linter_aliases = {
      \ 'mail': 'markdown'
      \}

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
      \   'reason': [
      \       'refmt',
      \   ],
      \}
