command! Todo :Grepper
      \ -side
      \ -noprompt
      \ -tool git
      \ -grepprg git grep -nIi '(TODO\|FIXME\|NOTE)'

augroup MyGrepper
  autocmd!
  autocmd User Grepper call setqflist([], 'r',
        \ {'context': {'bqf': {'pattern_hl': histget('/')}}}) |
        \ botright copen
  autocmd FileType GrepperSide
        \  silent execute 'keeppatterns v#'.b:grepper_side.'#>'
        \| silent normal! ggn
        \| setl wrap
augroup END

let g:grepper = {
      \ 'open': 0,
      \ 'quickfix': 1,
      \ 'searchreg': 1,
      \ 'highlight': 0,
      \ }

nmap <localleader><localleader> <Plug>(GrepperOperator)
xmap <localleader><localleader> <plug>(GrepperOperator)
nnoremap \ :Grepper -noprompt -tool rg -grepprg rg --vimgrep<space>
