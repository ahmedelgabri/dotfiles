return function(cmd, lsp)
  return {
    default_config = {
      cmd = cmd,
      filetypes = {
        -- html
        'aspnetcorerazor',
        'blade',
        'django-html',
        'edge',
        'ejs',
        'eruby',
        'gohtml',
        'haml',
        'handlebars',
        'hbs',
        'html',
        'html-eex',
        'jade',
        'leaf',
        'liquid',
        'markdown',
        'mdx',
        'mustache',
        'njk',
        'nunjucks',
        'php',
        'razor',
        'slim',
        'twig',
        -- css
        'css',
        'less',
        'postcss',
        'sass',
        'scss',
        'stylus',
        'sugarss',
        -- js
        'javascript',
        'javascript.jsx',
        'javascriptreact',
        'reason',
        'rescript',
        'typescript',
        'typescript.tsx',
        'typescriptreact',
        -- mixed
        'vue',
        'svelte',
      },
      init_options = {
        userLanguages = {
          eruby = 'html',
          ['javascript.jsx'] = 'javascriptreact',
          ['typescript.tsx'] = 'typescriptreact',
        },
      },
      root_dir = function(fname)
        return lsp.util.root_pattern('tailwind.config.js', 'tailwind.config.ts')(
          fname
        ) or lsp.util.root_pattern(
          'postcss.config.js',
          'postcss.config.ts'
        )(fname) or lsp.util.find_package_json_ancestor(fname) or lsp.util.find_node_modules_ancestor(
          fname
        ) or lsp.util.find_git_ancestor(fname)
      end,
      handlers = {
        ['tailwindcss/getConfiguration'] = function(_, _, params, _, bufnr, _)
          -- tailwindcss lang server waits for this repsonse before providing hover
          vim.lsp.buf_notify(
            bufnr,
            'tailwindcss/getConfigurationResponse',
            { _id = params._id }
          )
        end,
      },
    },
    docs = {
      description = [[ ]],
      default_config = {
        root_dir = [[root_pattern("package.json", ".git")]],
      },
    },
  }
end
