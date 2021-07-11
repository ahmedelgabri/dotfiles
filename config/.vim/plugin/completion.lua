local has_completion, completion = pcall(require, "compe")
local has_luasnip, luasnip = pcall(require, "luasnip")
local utils = require "_.utils"
local has_npairs, npairs = pcall(require, "nvim-autopairs")
local M = {}

_G._.completion = M

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
M.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return utils.t "<C-n>"
  elseif has_luasnip and luasnip.expand_or_jumpable() then
    return utils.t "<Plug>luasnip-expand-or-jump"
  elseif check_back_space() then
    return utils.t "<Tab>"
  else
    return vim.fn["compe#complete"]()
  end
end

M.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return utils.t "<C-p>"
  elseif has_luasnip and luasnip.jumpable(-1) then
    return utils.t "<Plug>luasnip-jump-prev"
  else
    return utils.t "<S-Tab>"
  end
end

M.completion_confirm = function()
  if vim.fn.pumvisible() ~= 0 then
    if vim.fn.complete_info()["selected"] ~= -1 then
      if has_luasnip and luasnip.choice_active() then
        return utils.t "<Plug>luasnip-next-choice"
      end
      return vim.fn["compe#confirm"](npairs.esc("<cr>"))
    else
      return npairs.esc("<cr>")
    end
  else
    return npairs.autopairs_cr()
  end
end

M.setup = function()
  if has_npairs then
    vim.g.completion_confirm_key = ""
  end

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
        nvim_lsp = true,
        nvim_lua = true,
        orgmode = true,
        emoji = true,
        luasnip = true,
        vsnip = false,
        ultisnips = false
      }
    }

    utils.gmap("i", "<Tab>", "v:lua._.completion.tab_complete()", {expr = true})
    utils.gmap("s", "<Tab>", "v:lua._.completion.tab_complete()", {expr = true})
    utils.gmap(
      "i",
      "<S-Tab>",
      "v:lua._completion.s_tab_complete()",
      {expr = true}
    )
    utils.gmap(
      "s",
      "<S-Tab>",
      "v:lua._.completion.s_tab_complete()",
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
      "v:lua._.completion.completion_confirm()",
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

M.setup()
