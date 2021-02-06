local has_completion, completion = pcall(require, "compe")
local utils = require "_.utils"

local M = {}

local function t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local function icons()
  require "vim.lsp.protocol".CompletionItemKind = {
    "", -- Text          = 1;
    "", -- Method        = 2;
    "ƒ", -- Function      = 3;
    "", -- Constructor   = 4;
    "Field", -- Field         = 5;
    "", -- Variable      = 6;
    "", -- Class         = 7;
    "ﰮ", -- Interface     = 8;
    "", -- Module        = 9;
    "", -- Property      = 10;
    "", -- Unit          = 11;
    "", -- Value         = 12;
    "了", -- Enum          = 13;
    "", -- Keyword       = 14;
    "﬌", -- Snippet       = 15;
    "", -- Color         = 16;
    "", -- File          = 17;
    "Reference", -- Reference     = 18;
    "", -- Folder        = 19;
    "", -- EnumMember    = 20;
    "", -- Constant      = 21;
    "", -- Struct        = 22;
    "Event", -- Event         = 23;
    "Operator", -- Operator      = 24;
    "TypeParameter" -- TypeParameter = 25;
  }
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif vim.fn.call("vsnip#available", {1}) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  else
    return t "<Tab>"
  end
end

_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    return t "<S-Tab>"
  end
end

M.setup = function()
  icons()

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
  end
end

return M
