-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))
local has_lsp, nvim_lsp = pcall(require, 'lspconfig')
local utils = require '_.utils'
local au = require '_.utils.au'
local map = require '_.utils.map'
local map_opts = { buffer = true, silent = true }

if not has_lsp then
  utils.notify 'LSP config failed to setup'
  return
end

local signs = { 'Error', 'Warning', 'Hint', 'Information' }

for _, type in pairs(signs) do
  -- vim.fn.sign_define('DiagnosticSign' .. type, {
  vim.fn.sign_define('LspDiagnosticsSign' .. type, {
    text = utils.get_icon(string.lower(type)),
    -- texthl = 'DiagnosticDefault' .. type,
    texthl = 'LspDiagnosticsDefault' .. type,
    linehl = '',
    numhl = '',
  })
end

vim.api.nvim_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local mappings = {
  ['<leader>a'] = { '<cmd>lua vim.lsp.buf.code_action()<CR>' },
  ['<leader>f'] = { '<cmd>lua vim.lsp.buf.references()<CR>' },
  ['<leader>r'] = { '<cmd>lua vim.lsp.buf.rename()<CR>' },
  ['K'] = { '<cmd>lua vim.lsp.buf.hover()<CR>' },
  ['<leader>ld'] = {
    '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ focusable = false,  border = "single" })<CR>',
  },
  ['[d'] = {
    '<cmd>lua vim.lsp.diagnostic.goto_next({ popup_opts = { border = "single", focusable = false, source = "always" }})<cr>',
  },
  [']d'] = {
    '<cmd>lua vim.lsp.diagnostic.goto_prev({ popup_opts = { border = "single", focusable = false, source = "always" }})<CR>',
  },
  ['<C-]>'] = { '<cmd>lua vim.lsp.buf.definition()<CR>' },
  ['<leader>D'] = { '<cmd>lua vim.lsp.buf.declaration()<CR>' },
  ['<leader>i'] = { '<cmd>lua vim.lsp.buf.implementation()<CR>' },
}

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = 'single', focusable = false, silent = true }
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = 'single', focusable = false, silent = true }
)

-- local diagnostic_ns = vim.api.nvim_create_namespace 'diagnostics'
-- vim.diagnostic.config({
--   virtual_text = false,
--   -- virtual_text = {
--   --   show_source = 'always',
--   --   spacing = 4,
--   --   prefix = '■', -- Could be '●', '▎', 'x'
--   -- },
--   underline = false,
--   signs = true,
--   update_in_insert = false,
-- }, diagnostic_ns)

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = false,
    -- virtual_text = {
    --   show_source = 'always',
    --   spacing = 4,
    --   prefix = '■', -- Could be '●', '▎', 'x'
    -- },
    underline = false,
    signs = true,
    update_in_insert = false,
  }
)

local on_attach = function(client)
  -- ---------------
  -- GENERAL
  -- ---------------
  client.config.flags.allow_incremental_sync = true

  -- ---------------
  -- MAPPINGS
  -- ---------------
  for lhs, rhs in pairs(mappings) do
    if lhs == 'K' then
      if vim.api.nvim_buf_get_option(0, 'filetype') ~= 'vim' then
        map.nnoremap(lhs, rhs[1], map_opts)
      end
    else
      map.nnoremap(lhs, rhs[1], map_opts)
      if #rhs == 2 then
        map.vnoremap(lhs, rhs[2], map_opts)
      end
    end
  end

  -- ---------------
  -- AUTOCMDS
  -- ---------------
  au.augroup('__LSP__', function()
    au.autocmd(
      'CursorHold',
      '<buffer>',
      'lua vim.lsp.diagnostic.show_line_diagnostics()'
    )
  end)

  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec(
      [[
      hi! link LspReferenceRead SpecialKey
      hi! link LspReferenceText SpecialKey
      hi! link LspReferenceWrite SpecialKey
      ]],
      false
    )

    au.augroup('__LSP_HIGHLIGHTS__', function()
      au.autocmd(
        'CursorHold',
        '<buffer>',
        'lua vim.lsp.buf.document_highlight()'
      )
      au.autocmd(
        'CursorHoldI',
        '<buffer>',
        'lua vim.lsp.buf.document_highlight()'
      )
      au.autocmd(
        'CursorMoved',
        '<buffer>',
        'lua vim.lsp.buf.clear_references()'
      )
    end)
  end

  if client.resolved_capabilities.code_lens then
    au.augroup('__LSP_CODELENS__', function()
      au.autocmd(
        'CursorHold,BufEnter,InsertLeave',
        '<buffer>',
        'lua vim.lsp.codelens.refresh()'
      )
    end)
  end
end

local servers = {
  cssls = {},
  bashls = {},
  vimls = {},
  pyright = {},
  dockerls = {},
  clojure_lsp = {},
  eslint = {},
  tailwindcss = {
    init_options = {
      userLanguages = {
        eruby = 'erb',
        eelixir = 'html-eex',
        ['javascript.jsx'] = 'javascriptreact',
        ['typescript.tsx'] = 'typescriptreact',
      },
    },
    handlers = {
      ['tailwindcss/getConfiguration'] = function(_, _, context)
        -- tailwindcss lang server waits for this repsonse before providing hover
        vim.lsp.buf_notify(
          context.bufnr,
          'tailwindcss/getConfigurationResponse',
          { _id = context.params._id }
        )
      end,
    },
  },
  zk = {
    cmd = { 'zk', 'lsp', '--log', '/tmp/zk-lsp.log' },
    root_dir = nvim_lsp.util.path.dirname,
  },
  efm = require '_.config.lsp.efm',
  sumneko_lua = require '_.config.lsp.sumneko',
  rust_analyzer = {},
  gopls = {
    cmd = { 'gopls', 'serve' },
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern('go.mod', '.git')(fname)
        or nvim_lsp.util.path.dirname(fname)
    end,
  },
  tsserver = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern 'tsconfig.json'(fname)
        or nvim_lsp.util.root_pattern(
          'package.json',
          'jsconfig.json',
          '.git'
        )(fname)
        or nvim_lsp.util.path.dirname(fname)
    end,
  },
  denols = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern 'deps.ts'(fname)
        or nvim_lsp.util.root_pattern 'mod.ts'(fname)
    end,
  },
  rnix = {},
  jsonls = {
    filetypes = { 'json', 'jsonc' },
    settings = {
      json = {
        -- Schemas https://www.schemastore.org
        schemas = {
          {
            fileMatch = { 'package.json' },
            url = 'https://json.schemastore.org/package.json',
          },
          {
            fileMatch = { 'tsconfig*.json' },
            url = 'https://json.schemastore.org/tsconfig.json',
          },
          {
            fileMatch = {
              '.prettierrc',
              '.prettierrc.json',
              'prettier.config.json',
            },
            url = 'https://json.schemastore.org/prettierrc.json',
          },
          {
            fileMatch = { '.eslintrc', '.eslintrc.json' },
            url = 'https://json.schemastore.org/eslintrc.json',
          },
          {
            fileMatch = { '.babelrc', '.babelrc.json', 'babel.config.json' },
            url = 'https://json.schemastore.org/babelrc.json',
          },
          {
            fileMatch = { 'lerna.json' },
            url = 'https://json.schemastore.org/lerna.json',
          },
          {
            fileMatch = { 'now.json', 'vercel.json' },
            url = 'https://json.schemastore.org/now.json',
          },
          {
            fileMatch = {
              '.stylelintrc',
              '.stylelintrc.json',
              'stylelint.config.json',
            },
            url = 'http://json.schemastore.org/stylelintrc.json',
          },
        },
      },
    },
  },
  yamlls = {
    settings = {
      yaml = {
        -- Schemas https://www.schemastore.org
        schemas = {
          ['http://json.schemastore.org/gitlab-ci.json'] = {
            '.gitlab-ci.yml',
          },
          ['https://json.schemastore.org/bamboo-spec.json'] = {
            'bamboo-specs/*.{yml,yaml}',
          },
          ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = {
            'docker-compose*.{yml,yaml}',
          },
          ['http://json.schemastore.org/github-workflow.json'] = '.github/workflows/*.{yml,yaml}',
          ['http://json.schemastore.org/github-action.json'] = '.github/action.{yml,yaml}',
          ['http://json.schemastore.org/prettierrc.json'] = '.prettierrc.{yml,yaml}',
          ['http://json.schemastore.org/stylelintrc.json'] = '.stylelintrc.{yml,yaml}',
          ['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}',
        },
      },
    },
  },
}

local capabilities = vim.lsp.protocol.make_client_capabilities()

if pcall(require, 'cmp_nvim_lsp') then
  capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
else
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    },
  }
end

for server, config in pairs(servers) do
  local server_disabled = (config.disabled ~= nil and config.disabled) or false

  if not server_disabled then
    nvim_lsp[server].setup(
      vim.tbl_deep_extend(
        'force',
        { on_attach = on_attach, capabilities = capabilities },
        config
      )
    )
  end
end
