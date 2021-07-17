local has_treesitter = pcall(require, 'nvim-treesitter')

if not has_treesitter then
  return
end

local parsers = require 'nvim-treesitter.parsers'

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
  textobjects = {
    select = {
      enable = true,
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
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
  },
}

require('_.utils').augroup('__treesitter__', function()
  vim.api.nvim_command(
    string.format(
      'autocmd FileType %s setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()',
      get_filetypes()
    )
  )
end)

if not has_treesitter then
  return
end

local parsers = require 'nvim-treesitter.parsers'

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
  textobjects = {
    select = {
      enable = true,
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
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
  },
}

require('_.utils').augroup('__treesitter__', function()
  vim.api.nvim_command(
    string.format(
      'autocmd FileType %s setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()',
      get_filetypes()
    )
  )
end)
