local au = require '_.utils.au'
local map = require '_.utils.map'

function SetUpLoupeHighlight()
  vim.cmd 'highlight! link QuickFixLine PmenuSel'

  vim.cmd 'highlight! clear Search'
  vim.cmd 'highlight! link Search Underlined'
end

au.augroup('__myloupe__', {
  { event = 'ColorScheme', pattern = '*', callback = SetUpLoupeHighlight },
})

SetUpLoupeHighlight()

map.nmap('<Leader>c', '<Plug>(LoupeClearHighlight)')
