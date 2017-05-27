let g:neoformat_scss_stylefmt = {
      \ 'exe': g:current_stylefmt_path,
      \ 'stdin': 1,
      \ }

let g:neoformat_css_stylefmt = {
      \ 'exe': g:current_stylefmt_path,
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_prettier = {
      \ 'exe': g:current_prettier_path,
      \ 'args': ['--stdin', '--no-semi', '--single-quote', '--trailing-comma es5'],
      \ 'stdin': 1,
      \ }

let g:neoformat_enabled_css = ['stylefmt']
let g:neoformat_enabled_scss = ['stylefmt']
let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_only_msg_on_error = 1

if len(g:current_flow_path)
  let g:neoformat_enabled_javascript += ['flow']
endif

" auto format on save
autocmd BufWritePre *.js Neoformat
