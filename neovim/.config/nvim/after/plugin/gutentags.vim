set tags=./.tags,.tags;

let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_ctags_exclude = ['*.min.*', '*node_modules*', '*bower_components*', '*.json', '*.html']
let g:gutentags_exclude_project_root = ['/usr/local', $HOME.'/.dotfiles', $HOME, $HOME.'/Desktop']
" let g:gutentags_resolve_symlinks = 1
" let g:gutentags_generate_on_missing = 1
" let g:gutentags_generate_on_new = 1
" let g:gutentags_generate_on_write = 1

