if vim.fn.exists ':Fern' == 0 then
  return
end

local utils = require '_.utils'
local au = require '_.utils.au'
local map = require '_.utils.map'

vim.g['fern#disable_default_mappings'] = 1
vim.g['fern#renderer#default#root_symbol'] = '┬'
vim.g['fern#renderer#default#leaf_symbol'] = ' '
vim.g['fern#renderer#default#collapsed_symbol'] = '├ '
vim.g['fern#renderer#default#expanded_symbol'] = '╰ '
vim.g['fern#default_hidden'] = 1

function init_fern()
  map.nmap(
    '<Plug>(fern-my-open-expand-collapse)',
    vim.fn['fern#smart#leaf'](
      utils.t '<Plug>(fern-action-open)',
      utils.t '<Plug>(fern-action-expand)',
      utils.t '<Plug>(fern-action-collapse)'
    ),
    { buffer = true, expr = true }
  )

  map.nmap('<CR>', '<Plug>(fern-my-open-expand-collapse)', { buffer = true })

  map.nmap('N', '<Plug>(fern-action-new-file)', { buffer = true })
  map.nmap('D', '<Plug>(fern-action-remove)', { buffer = true })
  map.nmap('H', '<Plug>(fern-action-hidden-toggle)', { buffer = true })
  map.nmap('R', '<Plug>(fern-action-reload)', { buffer = true })
  map.nmap('m', '<Plug>(fern-action-mark-toggle)', { buffer = true })
  map.nmap('s', '<Plug>(fern-action-open:split)', { buffer = true })
  map.nmap('v', '<Plug>(fern-action-open:vsplit)', { buffer = true })
  map.nmap('z', '<Plug>(fern-action-zoom)', { buffer = true })

  map.nmap('q', ':q<CR>', { buffer = true })
end

au.augroup('__fern-custom__', function()
  au.autocmd('FileType', 'fern', init_fern)
end)

map.nnoremap('-', ':Fern . -drawer -reveal=%<CR>', { silent = true })
