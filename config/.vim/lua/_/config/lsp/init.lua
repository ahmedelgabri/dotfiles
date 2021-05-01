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
local configs = require "lspconfig/configs"
local utils = require "_.utils"
local map_opts = {noremap = true, silent = true}

lspsaga.init_lsp_saga()

require "_.config.completion".setup()

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

vim.api.nvim_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

local default_mappings = {
  ["<leader>a"] = {"<Cmd>lua vim.lsp.buf.code_action()<CR>"},
  ["<leader>f"] = {"<cmd>lua vim.lsp.buf.references()<CR>"},
  ["<leader>r"] = {"<cmd>lua vim.lsp.buf.rename()<CR>"},
  ["K"] = {"<Cmd>lua vim.lsp.buf.hover()<CR>"},
  ["<leader>ld"] = {"<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>"},
  ["[d"] = {"<cmd>lua vim.lsp.diagnostic.goto_next()<cr>"},
  ["]d"] = {"<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>"},
  ["<C-]>"] = {"<Cmd>lua vim.lsp.buf.definition()<CR>"},
  ["<leader>D"] = {"<Cmd>lua vim.lsp.buf.declaration()<CR>"},
  ["<leader>i"] = {"<cmd>lua vim.lsp.buf.implementation()<CR>"}
}

local lspsaga_mappings = {
  ["<leader>d"] = {
    "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>"
  },
  ["<leader>a"] = {
    "<Cmd>lua require'lspsaga.codeaction'.code_action()<CR>",
    "<Cmd>'<,'>lua require'lspsaga.codeaction'.range_code_action()<CR>"
  },
  ["<leader>f"] = {"<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>"},
  ["<leader>s"] = {
    "<cmd>lua require'lspsaga.signaturehelp'.signature_help()<CR>"
  },
  ["<leader>r"] = {"<cmd>lua require'lspsaga.rename'.rename()<CR>"},
  ["<leader>ld"] = {
    "<cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>"
  },
  ["[d"] = {
    "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>"
  },
  ["]d"] = {
    "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>"
  },
  ["K"] = {"<cmd>lua require('lspsaga.hover').render_hover_doc()<cr>"},
  ["<C-f>"] = {"<cmd>lua require('lspsaga.hover').smart_scroll_hover(1)<cr>"},
  ["<C-b>"] = {"<cmd>lua require('lspsaga.hover').smart_scroll_hover(-1)<CR>"}
}

local mappings =
  vim.tbl_extend(
  "force",
  default_mappings,
  has_lspsaga and lspsaga_mappings or {}
)

local on_attach = function(client)
  client.config.flags.allow_incremental_sync = true
  require "lsp_signature".on_attach()

  for lhs, rhs in pairs(mappings) do
    if lhs == "K" then
      if vim.api.nvim_buf_get_option(0, "filetype") ~= "vim" then
        utils.bmap("n", lhs, rhs[1], map_opts)
      end
    else
      utils.bmap("n", lhs, rhs[1], map_opts)
      if #rhs == 2 then
        utils.bmap("v", lhs, rhs[2], map_opts)
      end
    end
  end

  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec(
      [[
      hi! link LspReferenceRead SpecialKey
      hi! link LspReferenceText SpecialKey
      hi! link LspReferenceWrite SpecialKey
      ]],
      false
    )
  end

  utils.augroup(
    "LSP",
    function()
      vim.api.nvim_command(
        "autocmd CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()"
      )
      if client.resolved_capabilities.document_highlight then
        vim.api.nvim_command(
          "autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()"
        )
        vim.api.nvim_command(
          "autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()"
        )
        vim.api.nvim_command(
          "autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()"
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
    virtual_text = false,
    -- virtual_text = {
    --   spacing = 4,
    --   prefix = "~"
    -- },
    underline = false,
    signs = true,
    update_in_insert = false
  }
)

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits"
  }
}

local tailwindlsp = "tailwindlsp"

configs[tailwindlsp] = require "_.config.lsp.tailwind".setup({tailwindlsp}, nvim_lsp)

local servers = {
  cssls = {},
  bashls = {},
  vimls = {},
  pyright = {},
  dockerls = {},
  sumneko_lua = require "_.config.lsp.sumneko",
  rust_analyzer = {
    capabilities = capabilities
  },
  gopls = {
    cmd = {"gopls", "serve"},
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern("go.mod", ".git")(fname) or
        vim.fn.getcwd()
    end
  },
  tsserver = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern("tsconfig.json")(fname) or
        nvim_lsp.util.root_pattern("package.json", "jsconfig.json", ".git")(
          fname
        ) or
        vim.fn.getcwd()
    end
  },
  denols = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern("deps.ts")(fname) or
        nvim_lsp.util.root_pattern("mod.ts")(fname)
    end
  },
  [tailwindlsp] = {},
  -- rnix = {},
  jsonls = {
    filetypes = {"json", "jsonc"},
    settings = {
      json = {
        -- Schemas https://www.schemastore.org
        schemas = {
          {
            fileMatch = {"package.json"},
            url = "https://json.schemastore.org/package.json"
          },
          {
            fileMatch = {"tsconfig*.json"},
            url = "https://json.schemastore.org/tsconfig.json"
          },
          {
            fileMatch = {
              ".prettierrc",
              ".prettierrc.json",
              "prettier.config.json"
            },
            url = "https://json.schemastore.org/prettierrc.json"
          },
          {
            fileMatch = {".eslintrc", ".eslintrc.json"},
            url = "https://json.schemastore.org/eslintrc.json"
          },
          {
            fileMatch = {".babelrc", ".babelrc.json", "babel.config.json"},
            url = "https://json.schemastore.org/babelrc.json"
          },
          {
            fileMatch = {"lerna.json"},
            url = "https://json.schemastore.org/lerna.json"
          },
          {
            fileMatch = {"now.json", "vercel.json"},
            url = "https://json.schemastore.org/now.json"
          },
          {
            fileMatch = {
              ".stylelintrc",
              ".stylelintrc.json",
              "stylelint.config.json"
            },
            url = "http://json.schemastore.org/stylelintrc.json"
          }
        }
      }
    }
  },
  yamlls = {
    settings = {
      yaml = {
        -- Schemas https://www.schemastore.org
        schemas = {
          ["http://json.schemastore.org/gitlab-ci.json"] = {".gitlab-ci.yml"},
          ["https://json.schemastore.org/bamboo-spec.json"] = {
            "bamboo-specs/*.{yml,yaml}"
          },
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
            "docker-compose*.{yml,yaml}"
          },
          ["http://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
          ["http://json.schemastore.org/github-action.json"] = ".github/action.{yml,yaml}",
          ["http://json.schemastore.org/prettierrc.json"] = ".prettierrc.{yml,yaml}",
          ["http://json.schemastore.org/stylelintrc.json"] = ".stylelintrc.{yml,yaml}",
          ["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}"
        }
      }
    }
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
