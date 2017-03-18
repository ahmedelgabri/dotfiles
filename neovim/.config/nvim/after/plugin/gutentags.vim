set tags=./.tags,.tags;
" let g:easytags_events = ['BufReadPost', 'BufWritePost']
" let g:easytags_async = 1
" let g:easytags_dynamic_files = 2
" let g:easytags_resolve_links = 1
" let g:easytags_suppress_ctags_warning = 1
let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_ctags_exclude = ['*.min', 'node_modules']
let g:gutentags_exclude_project_root = ['/usr/local', $HOME.'/.dotfiles', $HOME, $HOME.'/Desktop']
let g:gutentags_resolve_symlinks = 1

