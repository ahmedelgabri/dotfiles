scriptencoding utf-8

if !exists(':ALEInfo')
  finish
endif

let g:ale_fix_on_save = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_virtualtext_cursor = 1
" let g:ale_virtualtext_prefix = ' '
let g:ale_list_window_size = 5
let g:ale_warn_about_trailing_blank_lines = 1
let g:ale_warn_about_trailing_whitespace = 1
let g:ale_sign_error = functions#GetIcon('linter_error')
let g:ale_sign_warning = g:ale_sign_error
let g:ale_sign_style_error = functions#GetIcon('linter_style')
let g:ale_sign_style_warning = g:ale_sign_error
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_error_str='[ERROR]'
let g:ale_echo_msg_info_str='[INFO]'
let g:ale_echo_msg_warning_str='[WARNING]'
let g:ale_echo_msg_format = '%severity% -> %linter% -> %code% %s'
let g:ale_javascript_prettier_use_local_config = 1
function! s:PRETTIER_OPTIONS()
  return '--config-precedence prefer-file --single-quote --no-bracket-spacing --no-editorconfig --prose-wrap always --trailing-comma all --no-semi --end-of-line  lf --print-width ' . &textwidth
endfunction
let g:ale_javascript_prettier_options = s:PRETTIER_OPTIONS()
" Auto update the option when textwidth is dynamically set or changed in a ftplugin file
au! OptionSet textwidth let g:ale_javascript_prettier_options = s:PRETTIER_OPTIONS()

let g:ale_linter_aliases = {
      \ 'mail': 'markdown',
      \ 'html': ['html', 'css']
      \}

let g:ale_linters = {
      \ 'javascript': ['eslint'],
      \}

let g:ale_fixers = {
      \   '*'         : ['remove_trailing_lines', 'trim_whitespace'],
      \   'markdown'  : [ 'prettier' ],
      \   'javascript': [ 'prettier' ],
      \   'typescript': [ 'prettier' ],
      \   'css'       : [ 'prettier' ],
      \   'json'      : [ 'prettier' ],
      \   'scss'      : [ 'prettier' ],
      \   'yaml'      : [ 'prettier' ],
      \   'graphql'   : [ 'prettier' ],
      \   'html'      : [ 'prettier' ],
      \   'reason'    : [ 'refmt' ],
      \   'python'    : [ 'black' ],
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
      \   'package.json': {
      \       'ale_fixers': []
      \   },
      \   'Sites/personal/forks/.*': {
      \       'ale_fixers': []
      \   },
      \}
