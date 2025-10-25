-- Undo unwanted side-effects of `$VIMRUNTIME/ftplugin/lua.lua`.
vim.wo.foldexpr = 'v:lua.__.foldexpr(v:lnum)'
