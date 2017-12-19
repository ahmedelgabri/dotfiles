hi clear SignColumn
hi GitGutterAdd ctermbg=None guifg=green
hi GitGutterChange ctermbg=None guifg=orange
hi GitGutterDelete ctermbg=None guifg=red
hi GitGutterChangeDelete ctermbg=None guifg=DarkRed

let g:gitgutter_highlight_lines = 0
let g:gitgutter_async = 1
let g:gitgutter_diff_args = '--ignore-all-space'
let g:gitgutter_grep_command = executable('rg') ? 'rg' : 'grep'
