local has_completion, completion = pcall(require, "compe")
local utils = require "_.utils"
local has_npairs, npairs = pcall(require, "nvim-autopairs")

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
_G._.tab_complete = function()
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

_G._.s_tab_complete = function()
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
      autocomplete = true,
      min_length = 2,
      debug = false,
      preselect = "always",
      documentation = true,
      source = {
        path = true,
        tmux = true,
        buffer = true,
        spell = true,
        tags = true,
        conjure = true,
        vsnip = true,
        nvim_lsp = true,
        nvim_lua = true
      }
    }

    utils.gmap("i", "<Tab>", "v:lua._.tab_complete()", {expr = true})
    utils.gmap("s", "<Tab>", "v:lua._.tab_complete()", {expr = true})
    utils.gmap("i", "<S-Tab>", "v:lua._.s_tab_complete()", {expr = true})
    utils.gmap("s", "<S-Tab>", "v:lua._.s_tab_complete()", {expr = true})
    utils.gmap(
      "i",
      "<c-p>",
      "compe#complete()",
      {expr = true, noremap = true, silent = true}
    )

    if has_npairs then
      vim.g.completion_confirm_key = ""
      _G._.completion_confirm = function()
        if vim.fn.pumvisible() ~= 0 then
          if vim.fn.complete_info()["selected"] ~= -1 then
            return vim.fn["compe#confirm"](npairs.esc("<cr>"))
          else
            return npairs.esc("<cr>")
          end
        else
          return npairs.autopairs_cr()
        end
      end

      utils.gmap(
        "i",
        "<CR>",
        "v:lua._.completion_confirm()",
        {expr = true, noremap = true, silent = true}
      )
    else
      utils.gmap(
        "i",
        "<CR>",
        "compe#confirm('<CR>')",
        {expr = true, noremap = true, silent = true}
      )
    end

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
