if vim.fn.exists 'g:loaded_eunuch' == 0 then
  return
end

local map = require '_.utils.map'

-- This command & mapping shadows the ones in mappings.vim
-- if the plugin is available then use the plugin, if not fallback to the other one.

-- Move is more flexiabile thatn Rename
-- https://www.youtube.com/watch?v=Av2pDIY7nRY
map.nmap('<leader>m', ':Move <C-R>=expand("%")<cr>')

-- Delete the current file and clear the buffer
vim.cmd [[command! Del Delete]]
