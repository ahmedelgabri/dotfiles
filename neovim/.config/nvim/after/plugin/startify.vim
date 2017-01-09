let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ]

let g:startify_change_to_dir          = 0
let g:startify_change_to_vcs_root     = 0
let g:startify_session_delete_buffers = 1
let g:startify_update_oldfiles        = 1
let g:startify_use_env                = 1

hi! link StartifyHeader Normal
hi! link StartifyFile Directory
hi! link StartifyPath StatusLineNC
hi! link StartifySlash StartifyPath
hi! link StartifyBracket StartifyPath
hi! link StartifyNumber Title
