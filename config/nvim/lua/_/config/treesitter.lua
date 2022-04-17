return function()
  local has_treesitter = pcall(require, 'nvim-treesitter')

  if not has_treesitter then
    return
  end

  local parsers = require 'nvim-treesitter.parsers'
  local au = require '_.utils.au'
  local parser_config = parsers.get_parser_configs()

  local function get_filetypes()
    return vim.tbl_map(function(ft)
      return parser_config[ft].filetype or ft
    end, parsers.available_parsers())
  end

  require('nvim-treesitter.configs').setup {
    ensure_installed = 'all',
    ignore_install = { 'verilog' },
    indent = {
      enable = true,
    },
    query_linter = {
      enable = true,
      use_virtual_text = true,
      lint_events = { 'BufWrite', 'CursorHold' },
    },
    highlight = {
      enable = true,
      use_languagetree = true,
      disable = function(lang, bufnr) -- Disable in large files
        -- Remove the org part to use TS highlighter for some of the highlights (Experimental)
        return lang == 'org' or vim.api.nvim_buf_line_count(bufnr) > 10000
      end,
      -- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
      -- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/h57kxuv/?context=3
      -- Required since TS highlighter doesn't support all syntax features (conceal)
      additional_vim_regex_highlighting = {
        'python',
        'org',
        'lua',
        'vim',
        'zsh',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
          ['aC'] = '@conditional.outer',
          ['iC'] = '@conditional.inner',
        },
      },
    },
    autotag = {
      enable = true,
      filetypes = {
        'html',
        'javascript',
        'javascriptreact',
        'typescriptreact',
        'svelte',
        'vue',
        'javascript.jsx',
        'typescript.tsx',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
    rainbow = {
      enable = true,
      -- Enable only for lisp like languages
      disable = vim.tbl_filter(function(p)
        return p ~= 'clojure'
          and p ~= 'commonlisp'
          and p ~= 'fennel'
          and p ~= 'query'
      end, parsers.available_parsers()),
    },
    autopairs = {
      enable = true,
    },
    playground = {
      enable = true,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
    },
  }

  au.augroup('__treesitter__', {
    {
      event = 'FileType',
      pattern = get_filetypes(),
      command = 'setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()',
    },
  })
end
