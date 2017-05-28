scriptencoding utf-8

set showtabline=2
set laststatus=2    " LAST WINDOW WILL ALWAYS HAVE A STATUS LINE
set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------

" set statusline=
" set statusline+=%0*
" set statusline+=\ %{statusline#getMode()}\                        " Current mode
" set statusline+=%2*
" set statusline+=\ %{join(GitGutterGetHunkSummary())}
" set statusline+=\ %{gina#component#status#preset(\"fancy\")}
" set statusline+=%{gina#component#repo#branch()}
" set statusline+=\ %{gina#component#traffic#preset(\"fancy\")}\   " GIT BRANCH INFORMATION
" set statusline+=%8*
" set statusline+=\ %<
" set statusline+=%{statusline#fileprefix()}
" set statusline+=%6*
" set statusline+=%t
" set statusline+=\ %{statusline#modified()}
" set statusline+=%{statusline#readOnly()}\ %w
" set statusline+=%*
" set statusline+=%9*\ %=
" set statusline+=%{gutentags#statusline(\"⧖\")}
" set statusline+=\ %#warningmsg#
" set statusline+=%{exists(\"*ALEGetStatusLine\")?ALEGetStatusLine():''}
" set statusline+=%8*\ %{statusline#fileSize()}
" set statusline+=%8*\ %y
" set statusline+=%7*\ %{(&fenc!=''?&fenc:&enc)}
" set statusline+=\ %([%{&ff}]\ %)
" set statusline+=%{statusline#rhs()}
" set statusline+=%*
