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

  " StatusLine
  autocmd ColorScheme * execute printf('hi! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))
        \| execute 'hi! User5 ctermfg=red guifg=red'
        \| execute 'hi! User7 ctermfg=cyan guifg=cyan'
        \| execute printf('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('Identifier'),'fg', 'gui'), synIDattr(hlID('Identifier'),'fg', 'cterm'))
        \| execute printf('hi! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))
augroup END

let s:hour = strftime('%H')
let s:month = strftime('%m')
let s:summerNight = (s:month >= 4 && s:month < 10) && (s:hour <= 21 && s:hour > 7)
let s:winterNight = s:hour <= 18 && s:hour > 8
set background=dark

try
  if s:summerNight || s:winterNight
    colorscheme plain
  else
    colorscheme plain
  endif
catch
endtry
