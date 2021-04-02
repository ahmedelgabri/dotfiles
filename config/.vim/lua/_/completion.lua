local has_completion, completion = pcall(require, "compe")
local utils = require "_.utils"

local M = {}

local check_back_space = function()
  local col = vim.fn.col(".") - 1
  if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
    return true
  else
    return false
  end
end
-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return utils.t "<C-n>"
  elseif vim.fn.call("vsnip#available", {1}) == 1 then
    return utils.t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return utils.t "<Tab>"
  else
    return vim.fn["compe#complete"]()
  end
end

_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return utils.t "<C-p>"
  elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return utils.t "<Plug>(vsnip-jump-prev)"
  else
    return utils.t "<S-Tab>"
  end
end

M.setup = function()
  if has_completion then
    completion.setup {
      enabled = true,
      min_length = 2,
      debug = false,
      preselect = "always",
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

    utils.gmap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
    utils.gmap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
    utils.gmap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
    utils.gmap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
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

    utils.gmap(
      "i",
      "<C-f>",
      "compe#scroll({ 'delta': +4 })",
      {expr = true, noremap = true, silent = true}
    )

    utils.gmap(
      "i",
      "<C-d>",
      "compe#scroll({ 'delta': -4 })",
      {expr = true, noremap = true, silent = true}
    )
  end
end

return M
