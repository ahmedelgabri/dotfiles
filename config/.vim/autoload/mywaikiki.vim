function! mywaikiki#Load() abort
  if get(g:, 'waikiki_loaded', 0) == 1
    packadd vim-waikiki
    call waikiki#CheckBuffer(expand('%:p'))
  endif
endfun

function! mywaikiki#TargetsDict(name) abort
  return { 'myName': luaeval("require'_.notes'.my_name(_A)", a:name) }
endfun

function! mywaikiki#SetupBuffer() abort
  nmap  <buffer>  zl                    <Plug>(waikikiFollowLink)
  nmap  <buffer>  zh                    <Plug>(waikikiGoUp)
  xn    <buffer>  <LocalLeader>c        <Esc>m`g'<O```<Esc>g'>o```<Esc>``
  nmap  <buffer><silent> <LocalLeader>i :let &l:cocu = (&l:cocu=="" \ ? "n" : "")<cr>
  setl sw=2
  setl cole=2
endfun
