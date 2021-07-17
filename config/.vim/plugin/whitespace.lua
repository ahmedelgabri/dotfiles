local map = require '_.utils.map'
local au = require '_.utils.au'

vim.cmd [[command! Reindent call utils#Preserve("normal gg=G")]]

map.nnoremap('_=', ':Reindent<cr>')

au.augroup('__my_whitespace__', function()
  au.autocmd('BufWritePre', '*', function()
    if vim.fn['utils#should_strip_whitespace'] { 'markdown', 'diff' } then
      vim.fn['utils#Preserve'] '%s/\\s\\+$//e'
    end
  end)
  -- autocmd('BufWritePre', '*', [[v/\_s*\S/d']])
  -- autocmd('BufWritePre', '*', [[call utils#Preserve("%s#\($\n\s*\)\+\%$##")]])
end)
