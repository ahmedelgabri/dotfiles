if has('termguicolors')
  set termguicolors
end

set background=dark
let g:gruvbox_italic=1

let hour = strftime("%H")
if hour >= 6 && hour < 18
  colorscheme onedark
else
  colorscheme deep-space
endif

" I hate bold tabline
hi Tabline cterm=None gui=None
hi TablineFill cterm=None gui=None
hi TablineSel cterm=None gui=None

" Italics
hi Comment cterm=italic gui=italic

" Highlight long lines
hi OverLength ctermbg=red ctermfg=white guibg=#592929

