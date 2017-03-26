let g:neoformat_scss_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_css_stylefmt = {
      \ 'exe': nrun#Which('stylefmt'),
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_prettier_eslint = {
      \ 'exe': nrun#Which('prettier-eslint'),
      \ 'args': ['--stdin', '--tab-width 2', '--single-quote', '--trailing-comma=all', '--bracketSpacing'],
      \ 'stdin': 1,
      \ }

let g:neoformat_javascript_prettier_standard = {
      \ 'exe': nrun#Which('prettier-standard'),
      \ 'args': ['--stdin', '--fix'],
      \ 'stdin': 1,
      \ }

let g:neoformat_enabled_css = ['stylefmt']
let g:neoformat_enabled_scss = ['stylefmt']

if nrun#Which('eslint')
  let g:neoformat_enabled_javascript = ['prettier_eslint']
else
  let g:neoformat_enabled_javascript = ['prettier_standard']
endif

if nrun#Which('flow')
  let g:neoformat_enabled_javascript += ['flow']
endif
