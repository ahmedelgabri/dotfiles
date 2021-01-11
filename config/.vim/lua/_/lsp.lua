-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, nvim_lsp = pcall(require, "lspconfig")

if not has_lsp then
  return
end

local has_completion, completion = pcall(require, "completion")
local has_extensions = pcall(require, "lsp_extensions")
local utils = require "_.utils"
local map_opts = {noremap = true, silent = true}

if has_completion then
  require "_.completion".setup()

  utils.augroup(
    "COMPLETION",
    function()
      vim.api.nvim_command("au BufEnter * lua require'completion'.on_attach()")
      if has_extensions then
        vim.api.nvim_command(
          "au CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost * lua require'lsp_extensions'.inlay_hints()"
        )
      end
    end
  )
end

vim.api.nvim_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

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

  if has_completion then
    completion.on_attach(client)
  end

  -- Mappings.
  -- [TODO] Check conflicting mappings with these ones
  utils.bmap("n", "gd", "<Cmd>lua vim.lsp.buf.declaration()<CR>", map_opts)
  utils.bmap("n", "<C-]>", "<Cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
  utils.bmap("n", "ga", "<Cmd>lua vim.lsp.buf.code_action()<CR>", map_opts)
  if vim.api.nvim_buf_get_option(0, "filetype") ~= "vim" then
    utils.bmap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", map_opts)
  end
  utils.bmap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", map_opts)
  utils.bmap("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", map_opts)
  utils.bmap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", map_opts)
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

local function get_sumneko_command()
  local system_name

  if vim.fn.has("mac") == 1 then
    system_name = "macOS"
  elseif vim.fn.has("unix") == 1 then
    system_name = "Linux"
  else
    print("Unsupported system for sumneko")
  end

  -- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
  local sumneko_root_path =
    string.format(
    "%s/lspconfig/sumneko_lua/lua-language-server",
    vim.fn.stdpath("cache")
  )
  local sumneko_binary =
    string.format(
    "%s/bin/%s/lua-language-server",
    sumneko_root_path,
    system_name
  )

  return {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"}
end

require("nlua.lsp.nvim").setup(
  nvim_lsp,
  {
    cmd = get_sumneko_command(),
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
  tsserver = {}
}

for server, config in pairs(servers) do
  local server_disabled = (config.disabled ~= nil and config.disabled) or false

  if not server_disabled then
    nvim_lsp[server].setup(
      vim.tbl_deep_extend("force", {on_attach = on_attach}, config)
    )
  end
end
