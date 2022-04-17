if vim.fn.exists 'g:loaded_fugitive' == 0 then
  return
end

local map = require '_.utils.map'
local au = require '_.utils.au'

vim.g.fugitive_miro_domains = { 'code.devrtb.com' }

if vim.fn.exists 'g:fugitive_browse_handlers' == 0 then
  vim.g.fugitive_browse_handlers = {}
end

-- table.insert(
--   vim.g.fugitive_browse_handlers,
--   { vim.fn['miro#register'] 'miro#get_url' }
-- )
--
vim.cmd [[call insert(g:fugitive_browse_handlers, function('miro#get_url'))]]

-- Open current file on github.com
map.nnoremap('gb', ':GBrowse<cr>')
map.vnoremap('gb', ':GBrowse<cr>')
map.nnoremap('gs', ':Git<cr>')
map.vnoremap('gs', ':Git<cr>')

au.augroup('__my_fugitive__', {
  -- http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
  {
    event = 'BufReadPost',
    pattern = 'fugitive://*',
    callback = function()
      vim.opt.bufhidden = 'delete'
    end,
  },
  {
    event = 'User',
    pattern = 'fugitive',
    command = [[if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' | nnoremap <buffer> .. :edit %:h<CR> | endif]],
  },
})
