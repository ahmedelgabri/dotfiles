scriptencoding utf-8

" set showtabline=2
" set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------
set statusline=%!StatusLine()

function! StatusLine() abort
  let l:line='%* %{statusline#getMode()} %*'
  let l:line.='%<'
  let l:line.='%#ErrorMsg#%{&paste ? " ⍴ " : ""}%*'
  let l:line.='%#WarningMsg#%{&spell ? " ✎ " : ""}%*'
  let l:line.=statusline#GetHunks(GitGutterGetHunkSummary())
  let l:line.='%6* %{statusline#gitInfo()} '
  let l:line.='%4* %{statusline#fileprefix()}%*'
  let l:line.='%6*%t'
  let l:line.=statusline#modified()
  let l:line.='%5*'
  let l:line.=' %{statusline#readOnly()} %w%*'
  let l:line.='%9* %=%*'

  if get(b:, 'show_highlight')
    let l:id = synID(line('.'), col('.'), 1)
    let l:line .='%#WarningMsg#['
          \ . '%{synIDattr('.l:id.',"name")} as '
          \ . '%{synIDattr(synIDtrans('.l:id.'),"name")}'
          \ . '] %*'
  endif

  let l:line.=statusline#LinterStatus()
  let l:line.='%#WarningMsg#%{&ff != "unix" ? " ".&ff." ":""} %*'
  let l:line.='%#warningmsg#%{&fenc != "utf-8" && &fenc != "" ? " ".&fenc." " :""} %*'
  let l:line.='%4* %y'
  let l:line.='%4* %{statusline#fileSize()}'
  let l:line.='%4*%{statusline#rhs()}'
  let l:line.='%*'

  return l:line
endfunction

" execute 'highlight! link User1 Function'
" execute 'highlight! link User2 NonText'
" execute 'highlight! link User3 Todo'
execute 'highlight! link User4 NonText'
execute 'highlight! User5 ctermfg=red guifg=red'
execute 'highlight! User7 ctermfg=cyan guifg=cyan'
" execute 'highlight! link User8 PmenuSel'
" execute 'highlight! link User9 PmenuSel'

augroup MyStatusLine
  autocmd!
  if exists('#TextChangedI')
    autocmd BufWinEnter,BufWritePost,FileWritePost,TextChanged,TextChangedI,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  else
    autocmd BufWinEnter,BufWritePost,FileWritePost,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  endif
augroup END
