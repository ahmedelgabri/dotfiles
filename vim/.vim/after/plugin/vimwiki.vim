if !exists(':VimwikiIndex')
  finish
endif

let g:mapleader="\<Space>"
let g:vimwiki_folding = 'expr'
let g:vimwiki_dir_link = 'index'
let g:vimwiki_toc_header = 'Table of contents'
" let g:vimwiki_use_calendar=1
" $USER & full path is needed here instead of ~, because
" VimwikiDiaryGenerateLinks won't work properly
let g:vimwiki_list = [{
      \ 'path': '/Users/' . $USER . '/Box Sync/notes/vimwiki/',
      \ 'diary_rel_path': 'Diary/',
      \ 'diary_index': 'index',
      \ 'syntax': 'markdown',
      \ 'ext': '.md',
      \ 'auto_toc': 1,
      \}]


