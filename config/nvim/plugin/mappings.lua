-- Plugin mappings are inside plugin/after/<plugin name>.vim files

local map = require '_.utils.map'
local au = require '_.utils.au'

-- From https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
-- The `zzzv` keeps search matches in the middle of the window.
-- and make sure n will go forward when searching with ? or #
-- https://vi.stackexchange.com/a/2366/4600
map.nnoremap('n', [[(v:searchforward ? 'n' : 'N') . 'zzzv']], { expr = true })
map.nnoremap('N', [[(v:searchforward ? 'N' : 'n') . 'zzzv']], { expr = true })

-- Center { & } movements
map.nnoremap('{', '{zz')
map.nnoremap('}', '}zz')

-- Movement
-------------------
-- highlight last inserted text
map.nnoremap('gV', [[`[v`]']])

-- Move by 'display lines' rather than 'logical lines' if no v:count was
-- provided.  When a v:count is provided, move by logical lines.
map.nnoremap(
  'j',
  [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj']],
  { expr = true }
)
map.xnoremap(
  'j',
  [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj']],
  { expr = true }
)
map.nnoremap(
  'k',
  [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk']],
  { expr = true }
)
map.xnoremap(
  'k',
  [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk']],
  { expr = true }
)

-- Make `Y` behave like `C` and `D` (to the end of line)
map.nnoremap('Y', 'y$')

-- Disable arrow keys
map.imap('<up>', '<nop>')
map.imap('<down>', '<nop>')
map.imap('<left>', '<nop>')
map.imap('<right>', '<nop>')

-- Make arrowkey do something usefull, resize the viewports accordingly
map.nnoremap('<Right>', ':vertical resize -2<CR>')
map.nnoremap('<Left>', ':vertical resize +2<CR>')
map.nnoremap('<Down>', ':resize -2<CR>')
map.nnoremap('<Up>', ':resize +2<CR>')

map.nnoremap('<Leader><TAB>', '<C-w><C-w>')
map.nnoremap('<leader>sh', '<C-w>t<C-w>K<CR>')
map.nnoremap('<leader>sv', '<C-w>t<C-w>H<CR>')

-- https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
map.xnoremap('<', '<gv')
map.xnoremap('>', '>gv')

-- new file in current directory
map.nnoremap('<Leader>n', [[:e <C-R>=expand("%:p:h") . "/" <CR>]])

map.nnoremap('<Leader>p', [[:t.<left><left>]])
map.nnoremap('<leader>e', [[:exe getline(line('.'))<cr>]])

-- qq to record, Q to replay
map.nnoremap('Q', '@@')

-- Make dot work in visual mode
map.vnoremap('.', ':norm.<CR>')

-- For neovim terminal :term
-- nnoremap <leader>t  :vsplit +terminal<cr>
map.tnoremap(
  '<esc>',
  [[&filetype == 'fzf' ? "\<esc>" : "\<c-\>\<c-n>"]],
  { expr = true }
)

map.tnoremap('<M-h>', '<c-><c-n><c-w>h')
map.tnoremap('<M-j>', '<c-><c-n><c-w>j')
map.tnoremap('<M-k>', '<c-><c-n><c-w>k')
map.tnoremap('<M-l>', '<c-><c-n><c-w>l')

au.augroup('__MyTerm__', function()
  au.autocmd('TermOpen', '*', 'setl nonumber norelativenumber')
  au.autocmd('TermOpen', 'term://*', 'startinsert')
  au.autocmd('TermClose', 'term://*', 'stopinsert')
end)

map.nnoremap('<leader>z', ':call utils#ZoomToggle()<cr>', {
  silent = true,
})

map.nnoremap('<c-g>', ':call utils#SynStack()<cr>')

map.vmap('<Leader>hu', ':call utils#HtmlUnEscape()<cr>', {
  silent = true,
})

map.vmap('<Leader>he', ':call utils#HtmlEscape()<cr>', {
  silent = true,
})

-- maintain the same shortcut as vim-gtfo becasue it's in my muscle memory.
map.nnoremap('gof', ':call utils#OpenFileFolder()<cr>', {
  silent = true,
})

-- Allows you to visually select a section and then hit @ to run a macro on all lines
-- https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db#.3dcn9prw6
vim.cmd [[function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction]]

map.xnoremap('@', ':<C-u>call ExecuteMacroOverVisualRange()<CR>')

map.nnoremap(
  'K',
  [[:<C-U>exe 'help '. utils#helptopic()<CR>]],
  { silent = true, buffer = true }
)

-- Quick note taking per project
map.nmap('<Localleader>t', ':tab drop .git/todo.md<CR>')

-- More easier increment/decrement mappings
map.nnoremap('+', '<C-a>')
map.nnoremap('-', '<C-x>')
map.xnoremap('+', 'g<C-a>')
map.xnoremap('-', 'g<C-x>')

-- Execute "q" macro over visual line selections
map.xnoremap('Q', [[:'<,'>:normal @q<CR>]])
