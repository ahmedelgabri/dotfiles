function! s:SetUpLoupeHighlight()
  execute 'highlight! link QuickFixLine PmenuSel'

  highlight! clear Search
  execute 'highlight! link Search Underlined'
endfunction

augroup MyLoupe
  autocmd!
  autocmd ColorScheme * call <SID>SetUpLoupeHighlight()
augroup END

call s:SetUpLoupeHighlight()

nmap <Leader>c <Plug>(LoupeClearHighlight)
