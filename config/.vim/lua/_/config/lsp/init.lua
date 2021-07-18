-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, nvim_lsp = pcall(require, 'lspconfig')

if not has_lsp then
  return
end

local has_lspsaga, lspsaga = pcall(require, 'lspsaga')
local has_extensions = pcall(require, 'lsp_extensions')
local configs = require 'lspconfig/configs'
local utils = require '_.utils'
local au = require '_.utils.au'
local map = require '_.utils.map'
local map_opts = { buffer = true, silent = true }

lspsaga.init_lsp_saga()

au.augroup('__COMPLETION__', function()
  if has_extensions then
    au.autocmd(
      'CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost',
      '*',
      "lua require'lsp_extensions'.inlay_hints()"
    )
  end
end)

local signs = { 'Error', 'Warning', 'Hint', 'Information' }

for _, type in pairs(signs) do
  local hl = 'LspDiagnosticsSign' .. type
  local texthl = 'LspDiagnosticsDefault' .. type

  vim.fn.sign_define(hl, {
    text = utils.get_icon(string.lower(type)),
    texthl = texthl,
    linehl = '',
    numhl = '',
  })
end

vim.api.nvim_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local default_mappings = {
  ['<leader>a'] = { '<Cmd>lua vim.lsp.buf.code_action()<CR>' },
  ['<leader>f'] = { '<cmd>lua vim.lsp.buf.references()<CR>' },
  ['<leader>r'] = { '<cmd>lua vim.lsp.buf.rename()<CR>' },
  ['K'] = { '<Cmd>lua vim.lsp.buf.hover()<CR>' },
  ['<leader>ld'] = {
    '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({focusable=false})<CR>',
  },
  ['[d'] = { '<cmd>lua vim.lsp.diagnostic.goto_next()<cr>' },
  [']d'] = { '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>' },
  ['<C-]>'] = { '<Cmd>lua vim.lsp.buf.definition()<CR>' },
  ['<leader>D'] = { '<Cmd>lua vim.lsp.buf.declaration()<CR>' },
  ['<leader>i'] = { '<cmd>lua vim.lsp.buf.implementation()<CR>' },
}

local lspsaga_mappings = {
  ['<leader>d'] = {
    "<Cmd>lua require'lspsaga.provider'.preview_definition()<CR>",
  },
  ['<leader>a'] = {
    "<Cmd>lua require'lspsaga.codeaction'.code_action()<CR>",
    "<Cmd>'<,'>lua require'lspsaga.codeaction'.range_code_action()<CR>",
  },
  ['<leader>f'] = { "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>" },
  ['<leader>s'] = {
    "<cmd>lua require'lspsaga.signaturehelp'.signature_help()<CR>",
  },
  ['<leader>r'] = { "<cmd>lua require'lspsaga.rename'.rename()<CR>" },
  ['<leader>ld'] = {
    "<cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>",
  },
  ['[d'] = {
    "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>",
  },
  [']d'] = {
    "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>",
  },
  ['<C-f>'] = { "<cmd>lua require('lspsaga.hover').smart_scroll_hover(1)<cr>" },
  ['<C-b>'] = { "<cmd>lua require('lspsaga.hover').smart_scroll_hover(-1)<CR>" },
}

local mappings = vim.tbl_extend(
  'force',
  default_mappings,
  has_lspsaga and lspsaga_mappings or {}
)

local on_attach = function(client)
  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'single' }
  )

  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'single' }
  )
  -- ---------------
  -- GENERAL
  -- ---------------
  client.config.flags.allow_incremental_sync = true
  require('lsp_signature').on_attach()

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

-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#show-source-in-diagnostics
vim.lsp.handlers['textDocument/publishDiagnostics'] =
  function(_, _, params, client_id, _)
    local config = {
      virtual_text = false,
      -- virtual_text = {
      --   spacing = 4,
      --   prefix = "~"
      -- },
      underline = false,
      signs = true,
      update_in_insert = false,
    }

    local uri = params.uri
    local bufnr = vim.uri_to_bufnr(uri)

    if not bufnr then
      return
    end

    local diagnostics = params.diagnostics

    for i, v in ipairs(diagnostics) do
      diagnostics[i].message = string.format('%s: %s', v.source, v.message)
    end

    vim.lsp.diagnostic.save(diagnostics, bufnr, client_id)

    if not vim.api.nvim_buf_is_loaded(bufnr) then
      return
    end

    vim.lsp.diagnostic.display(diagnostics, bufnr, client_id, config)
  end

local tailwindlsp = 'tailwindlsp'

configs[tailwindlsp] = require('_.config.lsp.tailwind').setup(
  { tailwindlsp },
  nvim_lsp
)

local servers = {
  cssls = {},
  bashls = {},
  vimls = {},
  pyright = {},
  dockerls = {},
  [tailwindlsp] = {},
  efm = require '_.config.lsp.efm',
  sumneko_lua = require '_.config.lsp.sumneko',
  rust_analyzer = {},
  gopls = {
    cmd = { 'gopls', 'serve' },
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern('go.mod', '.git')(fname)
        or vim.loop.cwd()
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
        or vim.loop.cwd()
    end,
  },
  denols = {
    root_dir = function(fname)
      return nvim_lsp.util.root_pattern 'deps.ts'(fname)
        or nvim_lsp.util.root_pattern 'mod.ts'(fname)
    end,
  },
  -- rnix = {},
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
          ['http://json.schemastore.org/gitlab-ci.json'] = { '.gitlab-ci.yml' },
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
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  },
}

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
