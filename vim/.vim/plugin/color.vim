if has('termguicolors')
  set termguicolors
end

set background=dark
let g:gruvbox_contrast_dark='hard'
let g:gruvbox_invert_selection=0

let g:one_allow_italics = 1
let g:gruvbox_italic=1

colorscheme one

" Italics
hi Comment cterm=italic gui=italic

" let s:hour = strftime('%H')
" if s:hour >= 6 && s:hour < 18
"   colorscheme onedark
" else
"   colorscheme deep-space
" endif

" I hate bold tabline
hi Tabline cterm=NONE gui=NONE
hi TablineFill cterm=NONE gui=NONE
hi TablineSel cterm=NONE gui=NONE

" Highlight long lines
hi OverLength ctermbg=red ctermfg=white guibg=#592929


if has('nvim') && g:colors_name ==# 'codedark'
  highlight! link Error ErrorMsg
  highlight! link ALEError ErrorMsg
  highlight! link ALEErrorSign ErrorMsg
  highlight! link ALEWarning GitGutterChange
  highlight! link ALEWarningSign GitGutterChange
endif
