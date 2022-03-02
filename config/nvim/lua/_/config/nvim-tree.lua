return function()
  local map = require '_.utils.map'

  vim.g.nvim_tree_indent_markers = 1

  vim.g.nvim_tree_show_icons = {
    git = 1,
    folders = 0,
    files = 0,
    folder_arrows = 0,
  }

  -- Normally README.md gets highlighted by default, which is a bit distracting.
  vim.g.nvim_tree_special_files = {}

  map.nnoremap('--', ':NvimTreeFindFile<CR>', { silent = true })

  require('nvim-tree').setup {
    view = {
      width = '20%',
      auto_resize = true,
    },
    auto_close = true,
    update_focused_file = {
      enable = true,
    },
    actions = {
      open_file = {
        quit_on_open = false,
        window_picker = {
          enable = true,
        },
      },
    },
    -- vim-fugitive :GBrowse depends on netrw & this has to be set as early as possible
    -- maybe switch to https://github.com/ruifm/gitlinker.nvim?
    -- I only use fugitive for GBrowse 99% of the time & git branch in the statusline
    disable_netrw = false,
  }
end
