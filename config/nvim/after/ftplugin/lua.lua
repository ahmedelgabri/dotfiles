vim.opt_local.conceallevel = 2

-- Undo unwanted side-effects of `$VIMRUNTIME/ftplugin/lua.lua`.
vim.opt_local.foldexpr = 'v:lua.__.foldexpr(v:lnum)'
