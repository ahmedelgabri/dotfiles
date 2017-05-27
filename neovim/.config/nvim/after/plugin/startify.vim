let g:startify_custom_header = startify#fortune#cowsay('═','║','╔','╗','╝','╚')

let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ '^/tmp',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ]

let g:startify_padding_left = 5
let g:startify_relative_path = 1
let g:startify_fortune_use_unicode = 1
let g:startify_change_to_dir = 1
let g:startify_change_to_vcs_root = 1
" let g:startify_session_autoload = 1
let g:startify_update_oldfiles = 1
let g:startify_use_env = 1

hi! link StartifyHeader Normal
hi! link StartifyFile Directory
hi! link StartifyPath LineNr
hi! link StartifySlash StartifyPath
hi! link StartifyBracket StartifyPath
hi! link StartifyNumber Title

autocmd User Startified setlocal cursorline

