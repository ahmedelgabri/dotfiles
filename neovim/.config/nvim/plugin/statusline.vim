scriptencoding utf-8

set laststatus=2    " LAST WINDOW WILL ALWAYS HAVE A STATUS LINE
" set showtabline=2
" set tabline="%1T"

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------

" set statusline=
" set statusline+=%0*
" set statusline+=\ %{statusline#getMode()}\
" set statusline+=%2*
" set statusline+=\ %{join(GitGutterGetHunkSummary())}
" set statusline+=%8*
" set statusline+=\ %<
" set statusline+=%{statusline#gitInfo()}
" set statusline+=\ %{statusline#fileprefix()}
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

