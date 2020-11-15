local has_config, config = pcall(require, "nvim-treesitter.configs")

if not has_config then
  return
end

config.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true
    -- use_languagetree = false, -- Use this to enable language injection (this is very unstable)
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false -- Whether the query persists across vim sessions
  }
}
