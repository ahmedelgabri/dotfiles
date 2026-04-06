-- Plugin configurations using vim.pack (Neovim 0.12 built-in package manager)
-- Order matters: bootstrap specs first, then configure plugins

require('plugins.pack').bootstrap()

require 'plugins.snacks'
require 'plugins.oil'
require 'plugins.treesitter'
require 'plugins.git'
require 'plugins.mini'
require 'plugins.core'
require 'plugins.fzf'
require 'plugins.lsp'
require 'plugins.markdown'
require 'plugins.snippets'
require 'plugins.completion'
require 'plugins.autopairs'
require 'plugins.formatter'
require 'plugins.ai'
require 'plugins.leetcode'
