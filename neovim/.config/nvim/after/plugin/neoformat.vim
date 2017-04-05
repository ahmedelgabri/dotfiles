let g:neoformat_scss_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_css_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_prettier_standard = {
      \ 'exe': nrun#Which('prettier-standard'),
      \ 'args': ['--stdin', '--fix'],
      \ 'stdin': 1,
      \ }

let g:neoformat_enabled_css = ['stylefmt']
let g:neoformat_enabled_scss = ['stylefmt']
let g:neoformat_enabled_javascript = ['prettier_standard']

if nrun#Which('flow')
  let g:neoformat_enabled_javascript += ['flow']
endif


" auto format on save
" autocmd BufWritePre * Neoformat
