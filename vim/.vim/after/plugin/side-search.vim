" --heading and --stats are required!
let g:side_search_prg = 'ag --word-regexp'
  \. " --ignore='(*.map|*.min.*)'"
  \. " --heading --stats -B 1 -A 4"
let g:side_search_splitter = 'vnew'
let g:side_search_split_pct = 0.4

