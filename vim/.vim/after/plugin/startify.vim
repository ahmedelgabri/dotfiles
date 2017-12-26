scriptencoding utf-8

if !exists(':Startify')
  finish
endif

if has('nvim')
  let s:ascii = [
        \ '           _     ',
        \ '  __ _  __(_)_ _ ',
        \ ' /  \ |/ / /  / \',
        \ '/_/_/___/_/_/_/_/',
        \ '']
else
  let s:ascii = [
        \ '       _     ',
        \ ' _  __(_)_ _ ',
        \ '| |/ / /  / \',
        \ '|___/_/_/_/_/',
        \ '']
endif

let g:startify_ascii = [
      \ '',
      \ '        ,/     ',
      \ "      ,'/      ",
      \ "    ,' /       ". s:ascii[0],
      \ "  ,'  /_____,  ". s:ascii[1],
      \ ".'____    ,'   ". s:ascii[2],
      \ "     /  ,'     ". s:ascii[3],
      \ "    / ,'       ",
      \ "   /,'         ",
      \ "  /'           ",
      \ ''
      \ ]

let g:startify_custom_header = 'map(g:startify_ascii + startify#fortune#boxed(), "repeat(\" \", 5).v:val")'
let g:startify_list_order = [
      \ ['   Sessions:'], 'sessions',
      \ ['   Files:'], 'dir',
      \ ['   MRU'], 'files',
      \ ['   Bookmarks:'], 'bookmarks',
      \ ]
let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ '^/tmp',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'plugged/.*/doc',
      \ ]

let g:startify_padding_left = 5
let g:startify_relative_path = 1
let g:startify_fortune_use_unicode = 1
let g:startify_change_to_vcs_root = 1
let g:startify_update_oldfiles = 1
let g:startify_use_env = 1
let g:startify_files_number = 6
let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 1

hi! link StartifyHeader Normal
hi! link StartifyFile Directory
hi! link StartifyPath LineNr
hi! link StartifySlash StartifyPath
hi! link StartifyBracket StartifyPath
hi! link StartifyNumber Title

augroup MyStartify
  autocmd!
  autocmd User Startified setlocal cursorline
augroup END
