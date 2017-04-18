let g:ale_sign_error = '✗'
let g:ale_sign_warning = '!'
let g:ale_lint_on_save = 1
let g:ale_echo_msg_format = '[%linter%] %s'

let g:ale_linters = {'javascript': ['eslint', 'flow']}
let g:ale_javascript_standard_executable = nrun#Which('standard')
let g:ale_javascript_eslint_executable = nrun#Which('eslint')
let g:ale_javascript_flow_executable = nrun#Which('flow')
let g:ale_css_stylelint_executable = nrun#Which('stylelint')

if g:colors_name == 'codedark'
  highlight link ALEErrorSign ErrorMsg
  highlight link ALEWarningSign WarningMsg
  highlight Error guibg=None ctermbg=None
endif
