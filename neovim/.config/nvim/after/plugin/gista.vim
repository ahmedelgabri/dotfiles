" Github Auth for Gists
let g:gista#client#default_username = $GITHUB_USER
let g:gista#command#post#allow_empty_description = 1
let g:gista#command#post#interactive_description = 0

function! s:on_GistaPost() abort
  let l:gistid = g:gista#avars.gistid
  execute printf('Gista browse --gistid=%s', l:gistid)
endfunction

augroup my_vim_gista_autocmd
  autocmd! *
  autocmd User GistaPost call s:on_GistaPost()
augroup END


