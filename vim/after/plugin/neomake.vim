hi NeomakeErrorMsg ctermfg=009 ctermbg=None guifg=red guibg=NONE
hi NeomakeWarningMsg ctermfg=003 ctermbg=None guifg=yellow guibg=NONE

let g:neomake_open_list=2
let g:neomake_error_sign = { 'text': '✗', 'texthl': 'NeomakeErrorMsg', }
let g:neomake_warning_sign = { 'text': '!', 'texthl': 'NeomakeWarningMsg', }
let g:neomake_html_enabled_makers = ['tidy']

" Stylelint on demand
if findfile('.stylelintrc', '.;') !=# ''
  let g:neomake_css_enabled_makers = ['stylelint']
  let g:neomake_scss_enabled_makers = g:neomake_css_enabled_makers
  let g:neomake_scss_stylelint_maker = {
      \ 'exe': nrun#Which('stylelint'),
      \ 'args': ['--syntax', 'scss'],
      \ 'errorformat': '\ %l:%c\ %*[\✖]\ %m'
      \ }

endif

" JavaScript & JSX stuff
let g:neomake_javascript_enabled_makers = ['standard']
let g:neomake_jsx_enabled_makers = g:neomake_javascript_enabled_makers

" ESLint on demand
if findfile('.eslintrc', '.;') !=# '' || findfile('.eslintrc.js', '.;') !=# ''
  let g:neomake_javascript_enabled_makers = ['eslint']
  let g:neomake_jsx_enabled_makers = g:neomake_javascript_enabled_makers

  let g:neomake_javascript_eslint_exe = nrun#Which('eslint')
  let g:neomake_jsx_eslint_exe = g:neomake_javascript_eslint_exe
endif

" Flow on demand
if findfile('.flowconfig', '.;') !=# ''
  let g:flow_path = nrun#Which('flow')
  let g:neomake_javascript_flow_maker = {
      \ 'exe': 'sh',
      \ 'args': ['-c', g:flow_path.' --json --strip-root | flow-vim-quickfix'],
      \ 'errorformat': '%E%f:%l:%c\,%n: %m',
      \ 'cwd': '%:p:h'
      \ }

  let g:neomake_jsx_flow_maker = g:neomake_javascript_flow_maker

  let g:neomake_javascript_enabled_makers = g:neomake_javascript_enabled_makers + [ 'flow']
  let g:neomake_jsx_enabled_makers = g:neomake_javascript_enabled_makers
endif

autocmd! BufWritePost * Neomake

