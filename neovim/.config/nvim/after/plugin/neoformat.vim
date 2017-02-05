let g:neoformat_scss_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_css_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_prettier = {
      \ 'exe': nrun#Which('prettier'),
      \ 'args': ['--stdin', '--print-width 100', '--tab-width 2', '--single-quote', '--trailing-comma'],
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_standard = {
      \ 'exe': nrun#Which('standard'),
      \ 'args': ['--stdin', '--fix'],
      \ 'stdin': 1,
      \ }

let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_enabled_css = ['stylefmt']
let g:neoformat_enabled_scss = ['stylefmt']
