return function(on_attach)
  local ok, nls = pcall(require, 'null-ls')

  if not ok then
    return
  end

  local h = require 'null-ls.helpers'
  local au = require '_.utils.au'

  local refmt = {
    method = nls.methods.FORMATTING,
    filetypes = { 'rescript', 'reason' },
    generator = nls.formatter {
      command = 'refmt',
      to_stdin = true,
    },
  }

  local nixfmt = {
    method = nls.methods.FORMATTING,
    filetypes = { 'nix' },
    generator = nls.formatter {
      command = 'nixpkgs-fmt',
      to_stdin = true,
    },
  }

  local statixfmt = {
    method = nls.methods.FORMATTING,
    filetypes = { 'nix' },
    generator = nls.formatter {
      command = 'statix',
      args = { 'fix', '--stdin' },
      to_stdin = true,
    },
  }

  local jsonfmt = {
    method = nls.methods.FORMATTING,
    filetypes = { 'json' },
    generator = nls.formatter {
      command = 'jq',
      to_stdin = true,
    },
  }

  -- local nixlinter = {
  --   method = nls.methods.DIAGNOSTICS,
  --   filetypes = { 'nix' },
  --   generator = nls.generator {
  --     command = 'nix-linter',
  --     args = { '--json', '-' },
  --     to_stdin = true,
  --     from_stderr = true,
  --     -- choose an output format (raw, json, or line)
  --     format = 'json',
  --     check_exit_code = function(code)
  --       return code <= 1
  --     end,
  --     on_output = function(params)
  --       local diags = {}
  --       for _, d in ipairs(params.output) do
  --         table.insert(diags, {
  --           row = d.pos.spanBegin.sourceLine,
  --           col = d.pos.spanBegin.sourceColumn,
  --           end_col = d.pos.spanEnd.sourceColumn,
  --           code = d.offending,
  --           message = d.description,
  --           severity = 1,
  --         })
  --       end
  --       return diags
  --     end,
  --     -- on_output = h.diagnostics.from_pattern {
  --     --   {
  --     --     pattern = [[ (.*) at (\.\/.*):(\d+):(\d+)]],
  --     --     groups = { 'message', 'file', 'row', 'col' },
  --     --   },
  --     -- },
  --   },
  -- }

  nls.setup {
    debug = true,
    debounce = 150,
    on_attach = function(client)
      if client.resolved_capabilities.document_formatting then
        au.augroup('__LSP_FORMATTING__', function()
          au.autocmd(
            'BufWritePre',
            '<buffer>',
            'lua vim.lsp.buf.formatting_sync()'
          )
        end)
      end

      on_attach(client)
    end,
    sources = {
      refmt,
      nixfmt,
      statixfmt,
      jsonfmt,
      -- nixlinter,
      nls.builtins.formatting.prettier.with {
        filetypes = {
          'typescript',
          'javascript',
          'typescript.tsx',
          'javascript.jsx',
          'typescriptreact',
          'javascriptreact',
          'vue',
          'yaml',
          'html',
          'scss',
          'css',
          'markdown',
          'mdx',
          'json',
        },
        extra_args = {
          '--config-precedence',
          'prefer-file',
          '--single-quote',
          '--no-bracket-spacing',
          '--prose-wrap',
          'always',
          '--arrow-parens',
          'always',
          '--trailing-comma',
          'all',
          '--no-semi',
          '--end-of-line',
          'lf',
          '--print-width',
          vim.bo.textwidth <= 80 and 80 or vim.bo.textwidth,
        },
      },
      nls.builtins.formatting.stylua.with {
        extra_args = {
          '--indent-type',
          'Spaces',
          '--line-endings',
          'Unix',
          '--quote-style',
          'AutoPreferSingle',
          '--indent-width',
          vim.bo.tabstop,
          '--column-width',
          vim.bo.textwidth <= 80 and 80 or vim.bo.textwidth,
        },
      },
      nls.builtins.formatting.gofmt,
      nls.builtins.formatting.goimports,
      -- nls.builtins.diagnostics.golint,
      nls.builtins.diagnostics.shellcheck.with {
        filetypes = { 'sh', 'bash' },
      },
      nls.builtins.formatting.shfmt.with {
        filetypes = { 'sh', 'bash' },
      },
      nls.builtins.formatting.rustfmt,
      nls.builtins.formatting.black,
      nls.builtins.diagnostics.pylint,
      nls.builtins.diagnostics.hadolint,
      nls.builtins.diagnostics.vint,
      nls.builtins.diagnostics.vale,
      nls.builtins.diagnostics.statix,
    },
  }
end
