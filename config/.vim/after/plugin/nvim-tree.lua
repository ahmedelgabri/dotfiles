if vim.fn.exists ':NvimTreeToggle' == 0 then
  return
end

local map = require '_.utils.map'

vim.g.nvim_tree_auto_close = 1
-- 0 is supposed to be the default (ie. don't close tree when opening a file),
-- but it closes anyway; see: https://github.com/kyazdani42/nvim-tree.lua/issues/502
vim.g.nvim_tree_quit_on_open = 0

vim.g.nvim_tree_disable_window_picker = 1

vim.g.nvim_tree_indent_markers = 1

vim.g.nvim_tree_show_icons = {
  git = 1,
  folders = 0,
  files = 0,
  folder_arrows = 0,
}

-- Normally README.md gets highlighted by default, which is a bit distracting.
vim.g.nvim_tree_special_files = {}

map.nnoremap('-', ':NvimTreeFindFile<CR>', { silent = true })
