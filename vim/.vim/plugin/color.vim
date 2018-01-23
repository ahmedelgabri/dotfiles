if has('termguicolors')
  set termguicolors
end

augroup MyCustomColors
  autocmd!
  autocmd ColorScheme * hi! Tabline cterm=NONE gui=NONE
        \| hi! TablineFill cterm=NONE gui=NONE
        \| hi! TablineSel cterm=reverse gui=reverse
        \| hi! Comment cterm=italic gui=italic
        \| hi! link Conceal NonText
  " Highlight long lines
  " autocmd ColorScheme * hi! OverLength ctermbg=red ctermfg=white guibg=#592929

  autocmd ColorScheme codedark hi! link Error ErrorMsg
        \| hi! link ALEError ErrorMsg
        \| hi! link ALEErrorSign ErrorMsg
        \| hi! link ALEWarning GitGutterChange
        \| hi! link ALEWarningSign GitGutterChange
augroup END

let g:gruvbox_contrast_dark='hard'
let g:gruvbox_invert_selection=0
let g:gruvbox_italicize_comments=1
let g:one_allow_italics = 1

set background=dark

let s:hour = strftime('%H')
if s:hour >= 6 && s:hour < 18
  try
    colorscheme codedark
  catch
  endtry
else
  try
    colorscheme ayu
  catch
  endtry
endif

hi! link Conceal NonText
