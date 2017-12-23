syn match diffComment	"^%.*" " I set this to % to be able to write Markdown in PRs & Issues
hi diffAdded ctermfg=DarkGreen gui=bold guifg=DarkGreen
hi diffRemoved ctermfg=DarkRed gui=bold guifg=DarkRed
hi diffChanged ctermfg=DarkYellow guifg=DarkYellow
