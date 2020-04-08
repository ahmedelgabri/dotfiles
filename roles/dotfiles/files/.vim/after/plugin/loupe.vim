function! s:SetUpLoupeHighlight()
  execute 'highlight! link QuickFixLine PmenuSel'

  highlight! clear Search
  execute 'highlight! link Search Underlined'
endfunction

if has('autocmd')
  augroup MyLoupe
    autocmd!
    autocmd ColorScheme * call <SID>SetUpLoupeHighlight()
  augroup END
endif

call s:SetUpLoupeHighlight()

nmap <Leader>c <Plug>(LoupeClearHighlight)
