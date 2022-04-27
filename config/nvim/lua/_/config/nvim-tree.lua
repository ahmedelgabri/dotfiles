return function()
  local map = require '_.utils.map'

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
      width = 20,
    },
    update_focused_file = {
      enable = true,
    },
    renderer = {
      indent_markers = {
        enable = false,
      },
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = true,
        window_picker = {
          enable = false,
        },
      },
    },
    -- vim-fugitive :GBrowse depends on netrw & this has to be set as early as possible
    -- maybe switch to https://github.com/ruifm/gitlinker.nvim?
    -- I only use fugitive for GBrowse 99% of the time & git branch in the statusline
    disable_netrw = false,
  }
end
