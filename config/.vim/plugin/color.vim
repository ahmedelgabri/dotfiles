if has('termguicolors')
  set termguicolors
end

set background=dark
silent! colorscheme plain

augroup MyCustomColors
  autocmd!
  autocmd ColorScheme * hi! clear SignColumn
        \| hi! Tabline cterm=NONE gui=NONE
        \| hi! TablineFill cterm=NONE gui=NONE
        \| hi! TablineSel cterm=reverse gui=reverse
        \| hi! NonText ctermbg=NONE guibg=NONE
        \| if &background ==# 'dark' | hi! VertSplit gui=NONE guibg=NONE guifg=#333333 cterm=NONE ctermbg=NONE ctermfg=14 | endif
        \| hi! link ALEError DiffDelete
        \| hi! link ALEErrorSign DiffDelete
        \| hi! link ALEWarning DiffChange
        \| hi! link ALEWarningSign DiffChange
        \| execute(printf('hi! OverLength guibg=%s ctermbg=%s guifg=NONE ctermfg=NONE', '#222222', '234'))
        \| hi! link LspDiagnosticsDefaultError DiffDelete
        \| hi! link LspDiagnosticsDefaultWarning DiffChange
        \| hi! link LspDiagnosticsDefaultHint NonText
        \| hi! User5 ctermfg=red guifg=red
        \| hi! User7 ctermfg=cyan guifg=cyan
        \| execute(printf('hi! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('NonText', 'fg', 'gui'), utils#get_color('NonText','fg', 'cterm')))
        \| execute(printf('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Identifier', 'fg', 'gui'), utils#get_color('Identifier', 'fg', 'cterm')))
        \| execute(printf('hi! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('NonText', 'fg', 'gui'), utils#get_color('NonText', 'fg', 'cterm')))
        \| if has('+pumblend') | highlight PmenuSel blend=0 | endif
        \| execute(printf('hi! MutedImports gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Ignore', 'fg', 'gui'), utils#get_color('Ignore', 'fg', 'cterm')))
        \| execute(printf('hi! MutedImportsInfo gui=italic,bold cterm=italic,bold guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Comment', 'fg', 'gui'), utils#get_color('Comment', 'fg', 'cterm')))
        \| hi! link tsxTSInclude MutedImports
        \| hi! link jsxTSInclude MutedImports
        \| hi! link typescriptTSInclude MutedImports
        \| hi! link javascriptTSInclude MutedImports

  autocmd ColorScheme codedark,plain hi! link StartifyHeader Normal
        \| hi! link StartifyFile Directory
        \| hi! link StartifyPath LineNr
        \| hi! link StartifySlash StartifyPath
        \| hi! link StartifyBracket StartifyPath
        \| hi! link StartifyNumber Title

  autocmd ColorScheme plain execute(printf('hi! LineNr gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('VisualNOS', 'bg', 'gui'), utils#get_color('VisualNOS', 'bg', 'cterm')))
        \| hi! Comment cterm=italic gui=italic ctermfg=236 guifg=#555555
        \| execute(printf('hi! Pmenu gui=NONE cterm=NONE guibg=#222222 ctermbg=234 guifg=%s ctermfg=%s', utils#get_color('Pmenu', 'fg', 'gui'), utils#get_color('Pmenu', 'fg', 'cterm')))
        \| hi! link PmenuSel TermCursor
        \| hi! Whitespace ctermfg=235 guifg=#333333
        \| hi! link graphqlString Comment
        \| hi! link Todo Comment
        \| hi! link Conceal NonText
        \| hi! link Error ErrorMsg

  " Treesitter highlights
  " autocmd ColorScheme plain hi! link TSAnnotation
  "       \| hi! link TSAttribute
  "       \| hi! link TSBoolean Boolean
  "       \| hi! link TSCharacter Character
  "       \| hi! link TSComment Comment
  "       \| hi! link TSConditional
  "       \| hi! link TSConstBuiltin
  "       \| hi! link TSConstMacro
  "       \| hi! link TSConstant
  "       \| hi! link TSConstructor
  "       \| hi! link TSDanger
  "       \| hi! link TSEmphasis
  "       \| hi! link TSEnviroment
  "       \| hi! link TSEnviromentName
  "       \| hi! link TSError Error
  "       \| hi! link TSException
  "       \| hi! link TSField
  "       \| hi! link TSFloat
  "       \| hi! link TSFuncBuiltin
  "       \| hi! link TSFuncMacro
  "       \| hi! link TSFunction Function
  "       \| hi! link TSInclude
  "       \| hi! link TSKeyword Keyword
  "       \| hi! link TSKeywordFunction
  "       \| hi! link TSKeywordOperator
  "       \| hi! link TSLabel
  "       \| hi! link TSLiteral
  "       \| hi! link TSMath
  "       \| hi! link TSMethod
  "       \| hi! link TSNamespace
  "       \| hi! link TSNone
  "       \| hi! link TSNote
  "       \| hi! link TSNumber Number
  "       \| hi! link TSOperator
  "       \| hi! link TSParameter
  "       \| hi! link TSParameterReference
  "       \| hi! link TSProperty
  "       \| hi! link TSPunctBracket
  "       \| hi! link TSPunctDelimiter
  "       \| hi! link TSPunctSpecial
  "       \| hi! link TSRepeat
  "       \| hi! link TSStrike
  "       \| hi! link TSString String
  "       \| hi! link TSStringEscape
  "       \| hi! link TSStringRegex
  "       \| hi! link TSStrong
  "       \| hi! link TSSymbol
  "       \| hi! link TSTag
  "       \| hi! link TSTagDelimiter
  "       \| hi! link TSText
  "       \| hi! link TSTextReference
  "       \| hi! link TSTitle
  "       \| hi! link TSType
  "       \| hi! link TSTypeBuiltin
  "       \| hi! link TSURI
  "       \| hi! link TSUnderline
  "       \| hi! link TSVariable
  "       \| hi! link TSVariableBuiltin
  "       \| hi! link TSWarning
augroup END
