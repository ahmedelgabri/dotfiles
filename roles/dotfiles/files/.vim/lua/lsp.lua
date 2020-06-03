local has_lsp, nvim_lsp = pcall(require, 'nvim_lsp')
local has_completion, completion = pcall(require, 'completion')
local has_diagnostic, diagnostic = pcall(require, 'diagnostic')

if not has_lsp then
  return
end

-- for debugging
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))

-- highlights
vim.fn.sign_define('LspDiagnosticsErrorSign', {text='✖ ' or 'E', texthl='LspDiagnosticsError', linehl='', numhl=''})
vim.fn.sign_define('LspDiagnosticsWarningSign', {text='⚠' or 'W', texthl='LspDiagnosticsWarning', linehl='', numhl=''})
vim.fn.sign_define('LspDiagnosticsInformationSign', {text='ℹ' or 'I', texthl='LspDiagnosticsInformation', linehl='', numhl=''})
vim.fn.sign_define('LspDiagnosticsHintSign', {text='➤' or 'H', texthl='LspDiagnosticsHint', linehl='', numhl=''})

vim.api.nvim_command('highlight! link LspDiagnosticsError DiffDelete')
vim.api.nvim_command('highlight! link LspDiagnosticsWarning DiffChange')
vim.api.nvim_command('highlight! link LspDiagnosticsHint NonText')

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  local resolved_capabilities = client.resolved_capabilities

  -- Mappings.
  local opts = { noremap=true, silent=true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ld', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)

  if resolved_capabilities.document_highlight then
    vim.api.nvim_command[[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
    -- vim.api.nvim_command[[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
  end
  vim.api.nvim_command[[autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()]]

  if has_diagnostic then
    diagnostic.on_attach()
  end

  if has_completion then
    completion.on_attach({
        sorter = 'alphabet',
        matcher = {'exact', 'fuzzy'}
      })
  end
end

nvim_lsp.tsserver.setup{
  -- cmd = {
  --   "typescript-language-server",
  --   "--stdio",
  --   "--tsserver-log-file",
  --   "tslog"
  -- }
  -- See https://github.com/neovim/nvim-lsp/issues/237
  root_dir = nvim_lsp.util.root_pattern("tsconfig.json", ".git"),
  on_attach = on_attach
}
nvim_lsp.ocamlls.setup{ on_attach = on_attach }
nvim_lsp.cssls.setup{ on_attach = on_attach }
nvim_lsp.bashls.setup{ on_attach = on_attach }
nvim_lsp.vimls.setup{ on_attach = on_attach }
nvim_lsp.pyls.setup{ on_attach = on_attach }
nvim_lsp.rls.setup{
  settings = {
    rust = {
      clippy_preference = 'on'
    }
  },
  on_attach = on_attach
}

nvim_lsp.sumneko_lua.setup{
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
  on_attach = on_attach
}


-- JSON & YAML schemas http://schemastore.org/json/
nvim_lsp.jsonls.setup{
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
  on_attach = on_attach
}

nvim_lsp.yamlls.setup{
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
  on_attach = on_attach
}
