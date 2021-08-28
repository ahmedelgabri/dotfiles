return function()
  local map = require '_.utils.map'

  vim.g.undotree_WindowLayout = 2
  vim.g.undotree_SplitWidth = 50
  vim.g.undotree_SetFocusWhenToggle = 1

  map.nnoremap('<leader>u', ':UndotreeToggle<CR>', { silent = true })
end
