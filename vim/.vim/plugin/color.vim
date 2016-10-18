if has('termguicolors')
  set termguicolors
end

if has('nvim')
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
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

