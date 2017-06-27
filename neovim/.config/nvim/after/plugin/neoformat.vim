let g:neoformat_javascript_prettier = {
      \ 'exe': g:current_prettier_path,
      \  'args': ['--stdin', g:current_flow_path ==# 'flow not found' ? '' : '--parser flow', '--no-semi', '--single-quote', '--trailing-comma es5'],
      \ 'stdin': 1,
      \ }

let g:neoformat_json_prettier = {
      \ 'exe': g:current_prettier_path,
      \  'args': ['--stdin', '--parser json'],
      \ 'stdin': 1,
      \ }

let g:neoformat_css_prettier = {
      \ 'exe': g:current_prettier_path,
      \  'args': ['--stdin', '--parser postcss'],
      \ 'stdin': 1,
      \ }

let g:neoformat_scss_prettier = g:neoformat_css_prettier

let s:NEOFORMAT_ENABLED = ['prettier']
let g:neoformat_enabled_css = s:NEOFORMAT_ENABLED
let g:neoformat_enabled_scss = s:NEOFORMAT_ENABLED
let g:neoformat_enabled_json = s:NEOFORMAT_ENABLED
let g:neoformat_enabled_javascript = s:NEOFORMAT_ENABLED

let g:neoformat_only_msg_on_error = 1

" auto format on save
autocmd BufWritePre *.{js,jsx,json,css,scss} Neoformat
