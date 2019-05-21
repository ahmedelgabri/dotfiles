if has('termguicolors')
  set termguicolors
end

augroup MyCustomColors
  autocmd!
  autocmd ColorScheme * hi! Tabline cterm=NONE gui=NONE
        \| hi! TablineFill cterm=NONE gui=NONE
        \| hi! TablineSel cterm=reverse gui=reverse
        \| hi! NonText ctermbg=NONE guibg=NONE
        \| hi! link Todo Comment
        \| hi! link Conceal NonText
        \| hi! clear SignColumn
        \| hi! link VertSplit LineNr
        \| hi! User5 ctermfg=red guifg=red
        \| hi! User7 ctermfg=cyan guifg=cyan
        \| execute printf('hi! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))
        \| execute printf('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('Identifier'),'fg', 'gui'), synIDattr(hlID('Identifier'),'fg', 'cterm'))
        \| execute printf('hi! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))
        \| execute printf("hi! ALEInfoLine guifg=%s guibg=%s", &background=='light'?'#808000':'#ffff00', &background=='light'?'#ffff00':'#555500')
        \| execute printf("hi! ALEWarningLine guifg=%s guibg=%s", &background=='light'?'#808000':'#ffff00', &background=='light'?'#ffff00':'#555500')
        \| execute printf("hi! ALEErrorLine guifg=%s guibg=%s", '#ff0000', &background=='light'?'#ffcccc':'#550000')
        " \| hi! NormalFloat cterm=NONE ctermbg=0 gui=NONE guibg=#000000

  autocmd ColorScheme plain execute printf('hi! LineNr gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('VisualNOS'),'bg', 'gui'), synIDattr(hlID('VisualNOS'),'bg', 'cterm'))
        \| hi! Comment cterm=NONE gui=NONE ctermfg=236 guifg=#555555
        \| hi! link PmenuSel TermCursor

  autocmd ColorScheme codedark,plain hi! link StartifyHeader Normal
        \| hi! link StartifyFile Directory
        \| hi! link StartifyPath LineNr
        \| hi! link StartifySlash StartifyPath
        \| hi! link StartifyBracket StartifyPath
        \| hi! link StartifyNumber Title
        \| hi! link Error ErrorMsg
        \| hi! link ALEError ErrorMsg
        \| hi! link ALEErrorSign ErrorMsg
        \| hi! link ALEWarning DiffChange
        \| hi! link ALEWarningSign DiffChange

augroup END

set background=dark
colorscheme plain
