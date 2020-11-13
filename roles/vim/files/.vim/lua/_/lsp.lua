-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, lsp = pcall(require, "nvim_lsp")

if not has_lsp then
  return
end

local has_completion, completion = pcall(require, "completion")
local has_extensions = pcall(require, "lsp_extensions")
local utils = require "_.utils"
local map_opts = {noremap = true, silent = true}

if has_completion then
  require "_.completion".setup()

  -- Lazy loaded because it breaks if completion is not loaded already
  pcall(vim.cmd, [[packadd completion-buffers]])
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
  "LspDiagnosticsErrorSign",
  {
    text = utils.get_icon("error"),
    texthl = "LspDiagnosticsError",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsWarningSign",
  {
    text = utils.get_icon("warn"),
    texthl = "LspDiagnosticsWarning",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsInformationSign",
  {
    text = utils.get_icon("info"),
    texthl = "LspDiagnosticsInformation",
    linehl = "",
    numhl = ""
  }
)

vim.fn.sign_define(
  "LspDiagnosticsHintSign",
  {
    text = utils.get_icon("hint"),
    texthl = "LspDiagnosticsHint",
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
    "<leader>ld",
    "<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>",
    map_opts
  )

  utils.augroup(
    "LSP",
    function()
      vim.api.nvim_command(
        "autocmd CursorHold <buffer> lua vim.lsp.util.show_line_diagnostics()"
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

-- Uncomment to execute the extension test mentioned above.
-- local function custom_codeAction_callback(_, _, action)
-- 	print(vim.inspect(action))
-- end

-- lsp.callbacks['textDocument/codeAction'] = custom_codeAction_callback

local function root_pattern(...)
  local patterns = vim.tbl_flatten {...}

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lsp.util.search_ancestors(
        startpath,
        function(path)
          if
            lsp.util.path.exists(vim.fn.glob(lsp.util.path.join(path, pattern)))
           then
            return path
          end
        end
      )
    end
  end
end

local servers = {
  ocamlls = {},
  cssls = {},
  bashls = {},
  vimls = {},
  pyls = {},
  rust_analyzer = {},
  tsserver = {
    -- cmd = {
    --   "typescript-language-server",
    --   "--stdio",
    --   "--tsserver-log-file",
    --   "tslog"
    -- }
    -- See https://github.com/neovim/nvim-lsp/issues/237
    root_dir = root_pattern("tsconfig.json", "package.json", ".git")
  },
  sumneko_lua = {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";")
        },
        completion = {
          keywordSnippet = "Disable"
        },
        diagnostics = {
          enable = true,
          globals = {"vim", "spoon", "hs"}
        }
      }
    }
  }
}

for server, config in pairs(servers) do
  local server_disabled = (config.disabled ~= nil and config.disabled) or false

  if not server_disabled then
    lsp[server].setup(
      vim.tbl_deep_extend("force", {on_attach = on_attach}, config)
    )
  end
end
