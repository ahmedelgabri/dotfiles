" - Copy `Search` highlight to `LoupeHighlight`
" - Link `Search` to `VisualNOS`
function! s:SetUpLoupeHighlight()
  execute 'highlight! LoupeHighlight ' . pinnacle#extract_highlight('Search')
  highlight Search gui=underline,italic guifg=#F1544F guibg=#592929
  " highlight! link Search SpellBad
endfunction

if has('autocmd')
  augroup MyLoupe
    autocmd!
    autocmd ColorScheme * call s:SetUpLoupeHighlight()
  augroup END
endif

call s:SetUpLoupeHighlight()
