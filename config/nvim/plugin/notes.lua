local map = require '_.utils.map'

require '_.notes'

-- https://vimways.org/2019/personal-notetaking-in-vim/
-- https://danishpraka.sh/2020/02/23/journaling-in-vim.html

vim.cmd [[command! -complete=customlist,v:lua._.notes.get_notes_completion -nargs=* ONote call v:lua._.notes.note_in_obsidian(<f-args>)]]
vim.cmd [[command! -nargs=* -bang Notes call v:lua._.notes.search_notes(<q-args>, <bang>0)]]
vim.cmd [[command! -nargs=0 ZkIndex :lua require'lspconfig'.zk.index()]]
vim.cmd [[command! -nargs=? ZkNew :lua require'lspconfig'.zk.new(<args>)]]

map.nnoremap(
  '<leader>zn',
  ":ZkNew {dir = vim.fn.input('Target dir: '), title = vim.fn.input('Title: ') }<CR>"
)

map.nnoremap('<leader>sn', ':Notes<CR>', { silent = true })
map.nnoremap(
  '<localleader>o',
  ':call v:lua._.notes.open_in_obsidian()<CR>',
  { silent = true }
)
