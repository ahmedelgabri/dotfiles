local utils = require "_.utils"

if not utils.plugin_loaded("surround.vim") then
  return
end

vim.api.nvim_command("runtime macros/sandwich/keymap/surround.vim")
vim.g["sandwich#recipes"] =
  vim.tbl_extend(
  "force",
  vim.g["sandwich#recipes"],
  {
    {
      buns = {[[/\*\s*]], [[\s*\*/]]},
      regex = 1,
      filetype = {
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "javascript",
        "javascriptreact",
        "javascript.jsx"
      },
      input = {"/"}
    },
    {
      buns = {"${", "}"},
      filetype = {
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "zsh",
        "bash",
        "shell",
        "nix"
      },
      input = {"$"}
    }
  }
)
