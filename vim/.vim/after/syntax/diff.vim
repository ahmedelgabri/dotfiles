syn match diffComment	"^%.*" " I set this to % to be able to write Markdown in PRs & Issues
hi diffAdded cterm=bold ctermfg=DarkGreen gui=bold guifg=DarkGreen
hi diffRemoved cterm=bold ctermfg=DarkRed gui=bold guifg=DarkRed
hi diffChanged ctermfg=DarkYellow guifg=DarkYellow
