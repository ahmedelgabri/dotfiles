local has_config, config = pcall(require, "nvim-treesitter.configs")

if not has_config then
  return
end

vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"

config.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true
  },
  rainbow = {
    enable = true
    -- basically only enable for lisps
    -- disable = {
    --   "bash",
    --   "c",
    --   "c_sharp",
    --   "comment",
    --   "cpp",
    --   "css",
    --   "dart",
    --   "devicetree",
    --   "elm",
    --   "erlang",
    --   "go",
    --   "graphql",
    --   "haskell",
    --   "html",
    --   "java",
    --   "javascript",
    --   "jsdoc",
    --   "json",
    --   "julia",
    --   "kotlin",
    --   "ledger",
    --   "lua",
    --   "nix",
    --   "ocaml",
    --   "ocaml_interface",
    --   "ocamllex",
    --   "php",
    --   "python",
    --   "ql",
    --   "regex",
    --   "rst",
    --   "ruby",
    --   "rust",
    --   "scala",
    --   "svelte",
    --   "swift",
    --   "teal",
    --   "toml",
    --   "tsx",
    --   "typescript",
    --   "vue",
    --   "yaml"
    -- }
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
