local has_lsp, nvim_lsp = pcall(require, 'nvim_lsp')
local has_completion = pcall(require, 'completion')
local has_diagnostic, diagnostic = pcall(require, 'diagnostic')
local _ = pcall(vim.cmd, [[packadd completion-buffers]]) -- Lazy loaded because it breaks vim

if not has_lsp then
  return
end

-- for debugging
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))

if has_completion then
  vim.api.nvim_command("autocmd BufEnter * lua require'completion'.on_attach()")
end

vim.api.nvim_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local on_attach = function(client, bufnr)
  local resolved_capabilities = client.resolved_capabilities

  if has_diagnostic then
    diagnostic.on_attach()
  end

  -- Mappings.
  local opts = { noremap=true, silent=true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'ga', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  if vim.api.nvim_buf_get_option(0, 'filetype') ~= 'vim' then
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  end
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ld', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)

  vim.api.nvim_command('autocmd CursorHold <buffer> lua vim.lsp.util.show_line_diagnostics()')

  if resolved_capabilities.document_highlight then
    vim.api.nvim_command('autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()')
    vim.api.nvim_command('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
    vim.api.nvim_command('autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()')
  end
end

local servers = {
  {name = 'ocamlls'},
  {name = 'cssls'},
  {name = 'bashls'},
  {name = 'vimls'},
  {name = 'pyls'},
  {
    name = 'tsserver',
    config = {
      -- cmd = {
      --   "typescript-language-server",
      --   "--stdio",
      --   "--tsserver-log-file",
      --   "tslog"
      -- }
      -- See https://github.com/neovim/nvim-lsp/issues/237
      root_dir = nvim_lsp.util.root_pattern("tsconfig.json", ".git"),
    }
  },
  {
    name = 'rls',
    config = {
      settings = {
        rust = {
          clippy_preference = 'on'
        }
      },
    }
  },
  {
    name = 'sumneko_lua',
    config = {
      settings = {
        Lua = {
          runtime={
            version="LuaJIT",
          },
          diagnostics={
            enable=true,
            globals={"vim", "spoon", "hs"},
          },
        }
      },
    }
  },
  -- JSON & YAML schemas http://schemastore.org/json/
  {
    name = 'jsonls',
    config = {
      settings = {
        json = {
          schemas = {
            {
              description = 'TypeScript compiler configuration file',
              fileMatch = {'tsconfig.json', 'tsconfig.*.json'},
              url = 'http://json.schemastore.org/tsconfig'
            },
            {
              description = 'Lerna config',
              fileMatch = {'lerna.json'},
              url = 'http://json.schemastore.org/lerna'
            },
            {
              description = 'Babel configuration',
              fileMatch = {'.babelrc.json', '.babelrc', 'babel.config.json'},
              url = 'http://json.schemastore.org/lerna'
            },
            {
              description = 'ESLint config',
              fileMatch = {'.eslintrc.json', '.eslintrc'},
              url = 'http://json.schemastore.org/eslintrc'
            },
            {
              description = 'Bucklescript config',
              fileMatch = {'bsconfig.json'},
              url = 'https://bucklescript.github.io/bucklescript/docson/build-schema.json'
            },
            {
              description = 'Prettier config',
              fileMatch = {'.prettierrc', '.prettierrc.json', 'prettier.config.json'},
              url = 'http://json.schemastore.org/prettierrc'
            },
            {
              description = 'Vercel Now config',
              fileMatch = {'now.json', 'vercel.json'},
              url = 'http://json.schemastore.org/now'
            },
            {
              description = 'Stylelint config',
              fileMatch = {'.stylelintrc', '.stylelintrc.json', 'stylelint.config.json'},
              url = 'http://json.schemastore.org/stylelintrc'
            },
          }
        },
      },
    }
  },
  {
    name = 'yamlls',
    config = {
      settings = {
        yaml = {
          schemas = {
            ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
            ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
            ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
            ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
            ['http://json.schemastore.org/stylelintrc'] = '.stylelintrc.{yml,yaml}',
            ['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}'
          }
        }
      },
    }
  },
}

for _, lsp in ipairs(servers) do
  if lsp.config then
    lsp.config.on_attach = on_attach
  else
    lsp.config = {
      on_attach = on_attach
    }
  end

  nvim_lsp[lsp.name].setup(lsp.config)
end
