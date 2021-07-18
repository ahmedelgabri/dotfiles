if vim.fn.exists ':DevDocs' == 0 then
  return
end

local map = require '_.utils.map'

map.nmap('<localleader>dd', '<Plug>(devdocs-under-cursor)')

vim.g.devdocs_filetype_map = {
  java = 'java',
  ['javascript.jsx'] = 'react',
  ['typescript.tsx'] = 'react',
  javascript = 'javascript',
  typescript = 'typescript',
  lua = 'lua',
  python = 'python',
}
