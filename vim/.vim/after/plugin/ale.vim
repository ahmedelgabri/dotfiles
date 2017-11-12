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

" Don't auto fix (format) files inside `node_modules`, `forks` directory, minified files and jquery (for legacy codebases)
let g:ale_pattern_options_enabled = 1
let g:ale_pattern_options = {
      \   '\.min\.(js\|css)$': {
      \       'ale_linters': [],
      \       'ale_fixers': []
      \   },
      \   'jquery.*': {
      \       'ale_linters': [],
      \       'ale_fixers': []
      \   },
      \   'node_modules/.*': {
      \       'ale_linters': [],
      \       'ale_fixers': []
      \   },
      \   'Sites/forks/.*': {
      \       'ale_fixers': []
      \   },
      \}

