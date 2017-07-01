scriptencoding utf-8

set laststatus=2    " LAST WINDOW WILL ALWAYS HAVE A STATUS LINE
" set showtabline=2
" set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------
set statusline=
set statusline+=%0*
set statusline+=\ %{statusline#getMode()}
set statusline+=\ %<
set statusline+=%6*\ %{statusline#gitInfo()}
set statusline+=\ %4*
set statusline+=\ %{statusline#fileprefix()}
set statusline+=%6*
set statusline+=%t
set statusline+=%#errormsg#
set statusline+=\ %{statusline#modified()}
set statusline+=\ %{statusline#readOnly()}\ %w
set statusline+=%*
set statusline+=%9*\ %=
set statusline+=%#GitGutterDelete#
set statusline+=%{statusline#ALEGetError()}
set statusline+=\ %#GitGutterChange#
set statusline+=%{statusline#ALEGetWarning()}
set statusline+=\ %#GitGutterAdd#
set statusline+=%{statusline#ALEGetOk()}
set statusline+=%4*\ %y
set statusline+=%4*\ %{statusline#fileSize()}
set statusline+=%4*%{statusline#rhs()}
set statusline+=%*

execute 'highlight! User1 ' . pinnacle#extract_highlight('Function')
execute 'highlight! User2 ' . pinnacle#extract_highlight('NonText')
execute 'highlight! User3 ' . pinnacle#extract_highlight('Todo')
execute 'highlight! User4 ' . pinnacle#extract_highlight('WhiteSpace')
" execute 'highlight! User5 ' . pinnacle#extract_highlight('PmenuSel')
" execute 'highlight! User6 ' . pinnacle#extract_highlight('PmenuSel')
" execute 'highlight! User7 ' . pinnacle#extract_highlight('PmenuSel')
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

" augroup moonflyStatusLine
"     autocmd!
"     autocmd VimEnter,WinEnter,BufWinEnter,InsertLeave * call s:StatusLine()
"     autocmd WinLeave,FilterWritePost * call s:StatusLine()
"     autocmd InsertEnter * call s:StatusLine()
"     autocmd CursorMoved,CursorHold * call s:StatusLine()
"     if has('nvim')
"         autocmd TermOpen * call s:StatusLine()
"     endif
" augroup END
"
