-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, nvim_lsp = pcall(require, "lspconfig")

if not has_lsp then
  return
end

local has_lspsaga, lspsaga = pcall(require, "lspsaga")
local has_extensions = pcall(require, "lsp_extensions")
local utils = require "_.utils"
local map_opts = {noremap = true, silent = true}

lspsaga.init_lsp_saga(
  {
    border_style = 2
  }
)

require "_.completion".setup()

utils.augroup(
  "COMPLETION",
  function()
    if has_extensions then
      vim.api.nvim_command(
        "au CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost * lua require'lsp_extensions'.inlay_hints()"
      )
    end
  end
)

vim.fn.sign_define(
  "LspDiagnosticsSignError",
  {
    text = utils.get_icon("error"),
    texthl = "LspDiagnosticsDefaultError",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsSignWarning",
  {
    text = utils.get_icon("warn"),
    texthl = "LspDiagnosticsDefaultWarning",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsSignInformation",
  {
    text = utils.get_icon("info"),
    texthl = "LspDiagnosticsDefaultInformation",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsSignHint",
  {
    text = utils.get_icon("hint"),
    texthl = "LspDiagnosticsDefaultHint",
    linehl = "",
    numhl = ""
  }
)

local on_attach = function(client)
  local resolved_capabilities = client.resolved_capabilities

  -- Mappings.
  -- [TODO] Check conflicting mappings with these ones
  if has_lspsaga then
    utils.bmap(
      "n",
      "<C-]>",
      "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>",
      map_opts
    )
    utils.bmap(
      "n",
      "ga",
      "<Cmd>lua require'lspsaga.codeaction'.code_action()<CR>",
      map_opts
    )
    utils.bmap(
      "v",
      "ga",
      "<Cmd>lua require'lspsaga.codeaction'.range_code_action()<CR>",
      map_opts
    )
    utils.bmap(
      "n",
      "gr",
      "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>",
      map_opts
    )
    utils.bmap(
      "n",
      "gs",
      "<cmd>lua require'lspsaga.signaturehelp'.signature_help()<CR>",
      map_opts
    )
    utils.bmap(
      "n",
      "<leader>r",
      "<cmd>lua require'lspsaga.rename'.rename()<CR>",
      map_opts
    )
  else
    utils.bmap("n", "<C-]>", "<Cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
    utils.bmap("n", "ga", "<Cmd>lua vim.lsp.buf.code_action()<CR>", map_opts)
    utils.bmap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", map_opts)
    utils.bmap("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", map_opts)
  end
  if vim.api.nvim_buf_get_option(0, "filetype") ~= "vim" then
    utils.bmap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", map_opts)
  end
  utils.bmap("n", "gd", "<Cmd>lua vim.lsp.buf.declaration()<CR>", map_opts)
  utils.bmap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", map_opts)
  utils.bmap(
    "n",
    "<leader>dn",
    "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>",
    map_opts
  )
  utils.bmap(
    "n",
    "<leader>dp",
    "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>",
    map_opts
  )
  -- utils.bmap(
  --   "n",
  --   "<leader>ld",
  --   "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>",
  --   map_opts
  -- )

  utils.augroup(
    "LSP",
    function()
      vim.api.nvim_command(
        "autocmd CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()"
      )

      if resolved_capabilities.document_highlight then
        vim.api.nvim_command(
          "autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()"
        )
        vim.api.nvim_command(
          "autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()"
        )
        vim.api.nvim_command(
          "autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()"
        )
      end
    end
  )
end

-- https://github.com/nvim-lua/diagnostic-nvim/issues/73
vim.lsp.handlers["textDocument/publishDiagnostics"] =
  vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = true,
    -- virtual_text = {
    --   spacing = 4,
    --   prefix = "~"
    -- },
    underline = false,
    signs = true,
    update_in_insert = false
  }
)

require("nlua.lsp.nvim").setup(
  nvim_lsp,
  {
    on_attach = on_attach,
    globals = {"vim", "spoon", "hs"}
  }
)

local servers = {
  ocamlls = {},
  cssls = {},
  bashls = {},
  vimls = {},
  pyls = {},
  rust_analyzer = {},
  tsserver = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern("tsconfig.json")(fname) or
        nvim_lsp.util.root_pattern("package.json", "jsconfig.json", ".git")(
          fname
        ) or
        vim.fn.getcwd()
    end
  }
}

for server, config in pairs(servers) do
  local server_disabled = (config.disabled ~= nil and config.disabled) or false

  if not server_disabled then
    nvim_lsp[server].setup(
      vim.tbl_deep_extend("force", {on_attach = on_attach}, config)
    )
  end
end
