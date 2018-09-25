scriptencoding utf-8

if !exists(':Signify')
  finish
endif

let g:signify_vcs_list = [ 'git' ]
let g:signify_update_on_focusgained = 1
let g:signify_sign_add = '┃'
let g:signify_sign_delete = '◢'
let g:signify_sign_delete_first_line = '◥'
let g:signify_sign_change = '┃'
let g:signify_sign_changedelete = g:signify_sign_delete
let g:signify_vcs_cmds = {
      \ 'git': 'git diff --no-color --ignore-all-space --no-ext-diff -U0 -- %f',
      \ }

highlight! link SignifySignAdd             DiffAdd
highlight! link SignifySignChange          DiffChange
highlight! link SignifySignDelete          DiffDelete
highlight! link SignifySignChangeDelete    SignifySignChange
highlight! link SignifySignDeleteFirstLine SignifySignDelete

