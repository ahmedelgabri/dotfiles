scriptencoding utf-8

set laststatus=2    " LAST WINDOW WILL ALWAYS HAVE A STATUS LINE
" set showtabline=2
" set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------
set statusline=%!StatusLine()

function! StatusLine()
  let l:line='%* %{statusline#getMode()} %*'
  let l:line.='%<'
  let l:line.='%#ErrorMsg#%{&paste ? " ⍴ " : ""}%*'
  let l:line.='%#WarningMsg#%{&spell ? " ✎ " : ""}%*'
  let l:line.=statusline#GetHunks(GitGutterGetHunkSummary())
  let l:line.='%6* %{statusline#gitInfo()} '
  let l:line.='%4* %{statusline#fileprefix()}%*'
  let l:line.=statusline#modified()
  let l:line.='%t'
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

  let l:line.='%#GitGutterDelete#'
  let l:line.='%{statusline#ALEGetError()}'
  let l:line.='%#GitGutterChange#'
  let l:line.=' %{statusline#ALEGetWarning()}'
  let l:line.='%#GitGutterAdd#'
  let l:line.=' %{statusline#ALEGetOk()}'
  let l:line.='%#WarningMsg#%{&ff != "unix" ? " ".&ff." ":""} %*'
  let l:line.='%#warningmsg#%{&fenc != "utf-8" && &fenc != "" ? " ".&fenc." " :""} %*'
  let l:line.='%4* %y'
  let l:line.='%4* %{statusline#fileSize()}'
  let l:line.='%4*%{statusline#rhs()}'
  let l:line.='%*'

  return l:line
endfunction

" execute 'highlight! User1 ' . pinnacle#extract_highlight('Function')
" execute 'highlight! User2 ' . pinnacle#extract_highlight('NonText')
" execute 'highlight! User3 ' . pinnacle#extract_highlight('Todo')
execute 'highlight! User4 ' . pinnacle#extract_highlight('NonText')
execute 'highlight! User5 ctermfg=red guifg=red'
execute 'highlight! User7 ctermfg=cyan guifg=cyan'
" execute 'highlight! User8 ' . pinnacle#extract_highlight('PmenuSel')
" execute 'highlight! User9 ' . pinnacle#extract_highlight('PmenuSel')

augroup ahmedStatusLine
  autocmd!
  if exists('#TextChangedI')
    autocmd BufWinEnter,BufWritePost,FileWritePost,TextChanged,TextChangedI,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  else
    autocmd BufWinEnter,BufWritePost,FileWritePost,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  endif
augroup END
