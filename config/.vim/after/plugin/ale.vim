scriptencoding utf-8

if !exists(':ALEInfo')
  finish
endif

let g:ale_disable_lsp = 1
let g:ale_completion_enabled=0
let g:ale_set_signs = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 0
let g:ale_list_window_size = 5
let g:ale_sign_error = luaeval("require'_.utils'.get_icon('error')")
let g:ale_sign_warning = luaeval("require'_.utils'.get_icon('warn')")
let g:ale_sign_info = luaeval("require'_.utils'.get_icon('info')")
" let g:ale_sign_style_error = ''
" let g:ale_sign_style_warning = g:ale_sign_error
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_error_str='[ERROR]'
let g:ale_echo_msg_info_str='[INFO]'
let g:ale_echo_msg_warning_str='[WARNING]'
let g:ale_echo_msg_format = '%severity% %linter% -> [%code%] -> %s'

let g:ale_linter_aliases = {
      \ 'mail': 'markdown',
      \ 'html': ['html', 'css']
      \}

let g:rust_cargo_use_clippy = executable('cargo-clippy')
let g:ale_linters = {
      \ 'javascript': ['eslint'],
      \ 'typescript': ['eslint'],
      \ 'rust': ['analyzer'],
      \ 'go': ['gopls']
      \}

" Don't auto auto-format files inside `node_modules`, `forks` directory, minified files and jquery (for legacy codebases)
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
      \}
