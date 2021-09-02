local ok = pcall(function()
  vim.api.nvim_command 'runtime macros/sandwich/keymap/surround.vim'
  vim.g['sandwich#recipes'] = vim.tbl_extend(
    'force',
    vim.deepcopy(vim.g['sandwich#default_recipes']),
    {
      {
        buns = { [[/\*\s*]], [[\s*\*/]] },
        regex = 1,
        filetype = {
          'typescript',
          'typescriptreact',
          'typescript.tsx',
          'javascript',
          'javascriptreact',
          'javascript.jsx',
        },
        input = { '/' },
      },
      {
        buns = { '${', '}' },
        filetype = {
          'typescript',
          'typescriptreact',
          'typescript.tsx',
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'zsh',
          'bash',
          'shell',
          'nix',
        },
        input = { '$' },
      },
    }
  )
end)
