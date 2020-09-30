local has_config, config = pcall(require, 'nvim-treesitter.configs')

if not has_config then
  return
end

config.setup {
  ensure_installed = 'all', -- one of 'all', 'language', or a list of languages
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false -- Whether the query persists across vim sessions
  },
  highlight = {
    -- disable it when using plain colorscheme
    -- also because of https://github.com/nvim-treesitter/nvim-treesitter#i-experience-weird-highlighting-issues-similar-to-78
    enable = vim.g.colors_name ~= 'plain'
  },
  incremental_selection = {
    enable = true,
    disable = {},
    keymaps = {                  -- mappings for incremental selection (visual mappings)
      init_selection = "<cr>",    -- maps in normal mode to init the node/scope selection
      scope_incremental = "<cr>", -- increment to the upper scope (as defined in locals.scm)
      node_incremental = "<Tab>",  -- increment to the upper named parent
      node_decremental = "<S-Tab>",  -- decrement to the previous node
    }
  },
  refactor = {
    highlight_defintions = {
      enable = true
    },
    smart_rename = {
      enable = false,
      -- smart_rename = "grr" -- mapping to rename reference under cursor
    },
    navigation = {
      enable = true,
      goto_definition = "gnd", -- mapping to go to definition of symbol under cursor
      list_definitions = "gnD" -- mapping to list all definitions in current file
    }
  },
}
