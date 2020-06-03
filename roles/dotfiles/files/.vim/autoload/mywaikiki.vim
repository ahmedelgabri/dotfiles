let g:waikiki_wiki_roots=['~/Box/notes']
let g:waikiki_wiki_patterns = ['/wiki/', '\d+' ]
let g:waikiki_default_maps  = 1

function! mywaikiki#Load() abort
  if get(g:, 'waikiki_loaded', 0) == 1
    packadd vim-waikiki
    call waikiki#CheckBuffer(expand('%:p'))
  endif
endfun

" function! mywaikiki#SetupBuffer() abort
"   nmap  <buffer>  zl                    <Plug>(waikikiFollowLink)
"   nmap  <buffer>  zh                    <Plug>(waikikiGoUp)
"   xn    <buffer>  <LocalLeader>c        <Esc>m`g'<O```<Esc>g'>o```<Esc>``
"   nmap  <buffer><silent> <LocalLeader>i :let &l:cocu = (&l:cocu==""
"         \ ? "n" : "")<cr>
"   setl sw=2
"   setl cole=2
" endfun
"
" augroup Waikiki
"   au!
"   autocmd User setup call mywaikiki#SetupBuffer()
" augroup END
