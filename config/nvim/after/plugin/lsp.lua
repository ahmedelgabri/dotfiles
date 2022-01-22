-- for debugging
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

-- require('vim.lsp.log').set_level 'debug'
-- require('vim.lsp.log').set_format_func(vim.inspect)

local has_lsp, nvim_lsp = pcall(require, 'lspconfig')
local utils = require '_.utils'
local au = require '_.utils.au'
local map = require '_.utils.map'
local map_opts = { buffer = true, silent = true }

if not has_lsp then
  utils.notify 'LSP config failed to setup'
  return
end

local signs = { 'Error', 'Warn', 'Hint', 'Info' }

for _, type in pairs(signs) do
  vim.fn.sign_define('DiagnosticSign' .. type, {
    text = utils.get_icon(string.lower(type)),
    texthl = 'DiagnosticSign' .. type,
    linehl = '',
    numhl = '',
  })
end

local function getBorder(highlight)
  return {
    { '╭', highlight or 'FloatBorder' },
    { '─', highlight or 'FloatBorder' },
    { '╮', highlight or 'FloatBorder' },
    { '│', highlight or 'FloatBorder' },
    { '╯', highlight or 'FloatBorder' },
    { '─', highlight or 'FloatBorder' },
    { '╰', highlight or 'FloatBorder' },
    { '│', highlight or 'FloatBorder' },
  }
end

-- globally override borders
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#borders
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or getBorder()
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- wrap open_float to inspect diagnostics and use the severity color for border
-- https://neovim.discourse.group/t/lsp-diagnostics-how-and-where-to-retrieve-severity-level-to-customise-border-color/1679
vim.diagnostic.open_float = (function(orig)
  return function(bufnr, options)
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local opts = options or {}
    -- A more robust solution would check the "scope" value in `opts` to
    -- determine where to get diagnostics from, but if you're only using
    -- this for your own purposes you can make it as simple as you like
    local diagnostics = vim.diagnostic.get(opts.bufnr or 0, { lnum = lnum })
    local max_severity = vim.diagnostic.severity.HINT
    for _, d in ipairs(diagnostics) do
      -- Equality is "less than" based on how the severities are encoded
      if d.severity < max_severity then
        max_severity = d.severity
      end
    end
    local border_color = ({
      [vim.diagnostic.severity.HINT] = 'DiagnosticHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
      [vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
      [vim.diagnostic.severity.ERROR] = 'DiagnosticError',
    })[max_severity]
    opts.border = getBorder(border_color)
    orig(bufnr, opts)
  end
end)(vim.diagnostic.open_float)

vim.diagnostic.config {
  virtual_text = false,
  -- virtual_text = {
  --   source = 'always',
  --   spacing = 4,
  --   prefix = '■', -- Could be '●', '▎', 'x'
  -- },
  float = {
    source = 'always',
  },
  underline = true,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
}

vim.api.nvim_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local mappings = {
  ['<leader>a'] = { '<cmd>lua vim.lsp.buf.code_action()<CR>' },
  ['<leader>f'] = { '<cmd>lua vim.lsp.buf.references()<CR>' },
  ['<leader>r'] = { '<cmd>lua vim.lsp.buf.rename()<CR>' },
  ['K'] = { '<cmd>lua vim.lsp.buf.hover()<CR>' },
  ['<leader>ld'] = {
    '<cmd>lua vim.diagnostic.open_float(nil, { focusable = false,  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" }, source = "always" })<CR>',
  },
  ['[d'] = {
    '<cmd>lua vim.diagnostic.goto_next()<cr>',
  },
  [']d'] = {
    '<cmd>lua vim.diagnostic.goto_prev()<CR>',
  },
  ['<C-]>'] = { '<cmd>lua vim.lsp.buf.definition()<CR>' },
  ['<leader>D'] = { '<cmd>lua vim.lsp.buf.declaration()<CR>' },
  ['<leader>i'] = { '<cmd>lua vim.lsp.buf.implementation()<CR>' },
}

local handlers = {
  ['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { focusable = false, silent = true }
  ),
  ['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { focusable = false, silent = true }
  ),
}

local on_attach = function(client, bufnr)
  -- ---------------
  -- GENERAL
  -- ---------------
  client.config.flags.allow_incremental_sync = true

  -- ---------------
  -- MAPPINGS
  -- ---------------
  for lhs, rhs in pairs(mappings) do
    if lhs == 'K' then
      if vim.api.nvim_buf_get_option(bufnr, 'filetype') ~= 'vim' then
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
      au.autocmd('CursorHold', '<buffer>', function()
        vim.lsp.buf.document_highlight()
      end)
      au.autocmd('CursorMoved', '<buffer>', function()
        vim.lsp.buf.clear_references()
      end)
    end)
  end

  if client.resolved_capabilities.code_lens then
    au.augroup('__LSP_CODELENS__', function()
      au.autocmd('CursorHold,BufEnter,InsertLeave', '<buffer>', function()
        vim.lsp.codelens.refresh()
      end)
    end)
  end
end

local servers = {
  cssls = {},
  html = {},
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
      return not nvim_lsp.util.root_pattern '.flowconfig'(fname)
        and (
          nvim_lsp.util.root_pattern 'tsconfig.json'(fname)
          or nvim_lsp.util.root_pattern('package.json', 'jsconfig.json', '.git')(
            fname
          )
          or nvim_lsp.util.path.dirname(fname)
        )
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
            fileMatch = {
              '.babelrc',
              '.babelrc.json',
              'babel.config.json',
            },
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

local shared = {
  on_attach = on_attach,
  capabilities = capabilities,
  handlers = handlers,
  flags = {
    debounce_text_changes = 150,
  },
}

for server, config in pairs(servers) do
  local server_disabled = (config.disabled ~= nil and config.disabled) or false

  if not server_disabled then
    nvim_lsp[server].setup(vim.tbl_deep_extend('force', shared, config))
  end
end

require '_.config.lsp.null-ls'(on_attach)

pcall(function()
  require('zk').setup {
    -- create user commands such as :ZkNew
    create_user_commands = true,

    lsp = {
      -- `config` is passed to `vim.lsp.start_client(config)`
      config = vim.tbl_deep_extend('force', shared, {
        -- cmd = { 'zk', 'lsp', '--log', '/tmp/zk-lsp.log' },
        cmd = { 'zk', 'lsp' },
        name = 'zk',
        -- root_dir = nvim_lsp.util.path.dirname,
      }),

      auto_attach = {
        enabled = true,
        filetypes = { 'markdown' },
      },
    },
  }
end)
