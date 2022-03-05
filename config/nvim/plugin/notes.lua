local map = require '_.utils.map'

require '_.notes'

-- https://vimways.org/2019/personal-notetaking-in-vim/
-- https://danishpraka.sh/2020/02/23/journaling-in-vim.html

vim.cmd [[command! -complete=customlist,v:lua.__.notes.get_notes_completion -nargs=* ONote call v:lua.__.notes.note_in_obsidian(<f-args>)]]
vim.cmd [[command! -nargs=* -bang Notes call v:lua.__.notes.search_notes(<q-args>, <bang>0)]]

map.nnoremap(
  '<leader>zn',
  ":ZkNew {dir = vim.fn.input('Target dir: '), title = vim.fn.input('Title: ') }<CR>"
)

map.nnoremap('<leader>sn', ':Notes<CR>', { silent = true })
map.nnoremap(
  '<localleader>o',
  ':call v:lua.__.notes.open_in_obsidian()<CR>',
  { silent = true }
)
