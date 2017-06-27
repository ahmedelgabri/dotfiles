scriptencoding utf-8

let g:ale_sign_error = '✖'
let g:ale_sign_warning = '⚠'
let g:ale_statusline_format = ['E•%d', 'W•%d', 'OK']
let g:ale_echo_msg_format = '[%linter%] %s'

let g:ale_linters = {'javascript': ['eslint', 'flow']}
let g:ale_linter_aliases = {'reason': 'ocaml'}
let g:ale_javascript_eslint_executable = g:current_eslint_path
let g:ale_javascript_flow_executable = g:current_flow_path
