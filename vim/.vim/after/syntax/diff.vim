syn match diffComment "^%.*" " I set this to % to be able to write Markdown in PRs & Issues

hi! diffAdded cterm=italic ctermbg=green ctermfg=darkgreen gui=italic guibg=#3DB65C guifg=darkgreen
hi! diffRemoved cterm=italic ctermbg=red ctermfg=darkred gui=italic guibg=#F1544F guifg=darkred
hi! diffChanged ctermfg=darkyellow guifg=darkorange
