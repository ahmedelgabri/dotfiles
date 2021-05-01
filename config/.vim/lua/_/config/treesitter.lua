local function get_filetypes()
  local parsers = require("nvim-treesitter.parsers")
  local configs = parsers.get_parser_configs()
  return table.concat(
    vim.tbl_map(
      function(ft)
        return configs[ft].filetype or ft
      end,
      parsers.available_parsers()
    ),
    ","
  )
end

require "nvim-treesitter.configs".setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = {"comment"},
  highlight = {
    enable = true,
    -- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
    additional_vim_regex_highlighting = false
  },
  rainbow = {
    -- Lazy loaded only in lisp languages
    enable = true
  },
  autopairs = {
    enable = true
  },
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner"
      }
    }
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false -- Whether the query persists across vim sessions
  }
}

require "_.utils".augroup(
  "__treesitter__",
  function()
    vim.api.nvim_command(
      string.format(
        "autocmd FileType %s setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()",
        get_filetypes()
      )
    )
  end
)
