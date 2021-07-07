-- leader is space, only works with double quotes around it?!
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- My global namespace
_G._ = {}

vim.g.VIMHOME = vim.fn.stdpath("config")
vim.g.VIMDATA = vim.fn.stdpath("data")

-- Skip vim plugins {{{
-- Skip loading menu.vim, saves ~100ms
vim.g.did_install_default_menus = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_rrhelper = 1
-- }}}

-- Providers {{{
-- Set them directly if they are installed, otherwise disable them. To avoid the
-- runtime check cost, which can be slow.
-- Python This must be here becasue it makes loading vim VERY SLOW otherwise
vim.g.python_host_skip_check = 1
-- Disable python2 provider
vim.g.loaded_python_provider = 0

vim.g.python3_host_skip_check = 1

if vim.fn.executable("python3") == 1 then
  vim.g.python3_host_prog = vim.fn.exepath("python3")
else
  vim.g.loaded_python3_provider = 0
end

if vim.fn.executable("neovim-node-host") == 1 then
  vim.g.node_host_prog = vim.fn.exepath("neovim-node-host")
else
  vim.g.loaded_node_provider = 0
end

if vim.fn.executable("neovim-ruby-host") == 1 then
  vim.g.ruby_host_prog = vim.fn.exepath("neovim-ruby-host")
else
  vim.g.loaded_ruby_provider = 0
end

vim.g.loaded_perl_provider = 0
-- }}}

require "_.plugins"

-- Overrrides {{{
local vimrc_local = string.format("%s%s", os.getenv("HOME"), "/.nvimrc.lua")

if vim.fn.filereadable(vimrc_local) == 1 then
  vim.cmd(string.format("luafile %s", vimrc_local))
end
-- }}}

-- After this file is sourced, plug-in code will be evaluated.
-- See ~/.vim/after for files evaluated after that.
-- See `:scriptnames` for a list of all scripts, in evaluation order.
-- Launch Vim with `vim --startuptime vim.log` for profiling info.
--
-- To see all leader mappings, including those from plug-ins:
--
--   vim -c 'set t_te=' -c 'set t_ti=' -c 'map <space>' -c q | sort
