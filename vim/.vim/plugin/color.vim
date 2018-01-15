if has('termguicolors')
  set termguicolors
end

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
