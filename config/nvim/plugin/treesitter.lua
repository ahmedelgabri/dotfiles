local has_treesitter = pcall(require, 'nvim-treesitter')

if not has_treesitter then
  return
end

local parsers = require 'nvim-treesitter.parsers'
local au = require '_.utils.au'

local function get_filetypes()
  local configs = parsers.get_parser_configs()
  return table.concat(
    vim.tbl_map(function(ft)
      return configs[ft].filetype or ft
    end, parsers.available_parsers()),
    ','
  )
end

require('nvim-treesitter.configs').setup {
  ensure_installed = 'maintained', -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = { 'verilog' },
  indent = {
    enable = true,
  },
  highlight = {
    enable = true,
    -- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
    -- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/h57kxuv/?context=3
    additional_vim_regex_highlighting = { 'python' },
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

au.augroup('__treesitter__', function()
  au.autocmd(
    'FileType',
    get_filetypes(),
    'setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()'
  )
end)