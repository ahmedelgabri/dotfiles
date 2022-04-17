local au = require '_.utils.au'
local map = require '_.utils.map'
local hl = require '_.utils.highlight'

function SetUpLoupeHighlight()
  hl.group('QuickFixLine', { link = 'PmenuSel' })
  vim.cmd 'highlight! clear Search'
  hl.group('Search', { link = 'Underlined' })
end

au.augroup('__myloupe__', {
  { event = 'ColorScheme', pattern = '*', callback = SetUpLoupeHighlight },
})

SetUpLoupeHighlight()

map.nmap('<Leader>c', '<Plug>(LoupeClearHighlight)')
