local has_completion, completion = pcall(require, "compe")
local utils = require "_.utils"

local M = {}

M.setup = function()
  if has_completion then
    completion.setup {
      enabled = true,
      min_length = 2,
      debug = false,
      source = {
        path = true,
        buffer = true,
        spell = true,
        tags = true,
        conjure = true,
        vsnip = true,
        nvim_lsp = true,
        nvim_lua = true
      }
    }

    utils.gmap(
      "i",
      "<Tab>",
      [[pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "\<Tab>"]],
      {expr = true}
    )
    utils.gmap(
      "s",
      "<Tab>",
      [[pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "\<Tab>"]],
      {expr = true}
    )
    utils.gmap(
      "i",
      "<S-Tab>",
      [[pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "\<S-Tab>"]],
      {expr = true}
    )
    utils.gmap(
      "s",
      "<S-Tab>",
      [[pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "\<S-Tab>"]],
      {expr = true}
    )

    utils.gmap(
      "i",
      "<c-p>",
      "compe#complete()",
      {expr = true, noremap = true, silent = true}
    )
    utils.gmap(
      "i",
      "<CR>",
      "compe#confirm('<CR>')",
      {expr = true, noremap = true, silent = true}
    )

    utils.gmap(
      "i",
      "<C-e>",
      "compe#close('<C-e>')",
      {expr = true, noremap = true, silent = true}
    )
  end
end

return M
