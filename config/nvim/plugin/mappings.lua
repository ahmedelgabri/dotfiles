-- Plugin mappings are inside plugin/after/<plugin name>.vim files

local au = require '_.utils.au'

-- From https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
-- The `zzzv` keeps search matches in the middle of the window.
-- and make sure n will go forward when searching with ? or #
-- https://vi.stackexchange.com/a/2366/4600
vim.keymap.set(
	{ 'n' },
	'n',
	[[(v:searchforward ? 'n' : 'N') . 'zzzv']],
	{ expr = true }
)
vim.keymap.set(
	{ 'n' },
	'N',
	[[(v:searchforward ? 'N' : 'n') . 'zzzv']],
	{ expr = true }
)

-- Center { & } movements
vim.keymap.set({ 'n' }, '{', '{zz')
vim.keymap.set({ 'n' }, '}', '}zz')

-- Movement
-------------------
-- highlight last inserted text
vim.keymap.set({ 'n' }, 'gV', [[`[v`]']])

-- Move by 'display lines' rather than 'logical lines' if no v:count was
-- provided.  When a v:count is provided, move by logical lines.
vim.keymap.set(
	{ 'n', 'x' },
	'j',
	[[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj']],
	{ expr = true }
)
vim.keymap.set(
	{ 'n', 'x' },
	'k',
	[[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk']],
	{ expr = true }
)

if not vim.fn.has 'nvim-0.6' then
	-- Make `Y` behave like `C` and `D` (to the end of line)
	vim.keymap.set({ 'n' }, 'Y', 'y$', { desc = '[Y]ank till end of line' })
end

-- Disable arrow keys
vim.keymap.set({ 'i' }, '<up>', '<nop>', { remap = true })
vim.keymap.set({ 'i' }, '<down>', '<nop>', { remap = true })
vim.keymap.set({ 'i' }, '<left>', '<nop>', { remap = true })
vim.keymap.set({ 'i' }, '<right>', '<nop>', { remap = true })

-- Make arrowkey do something usefull, resize the viewports accordingly
vim.keymap.set({ 'n' }, '<Right>', ':vertical resize -2<CR>')
vim.keymap.set({ 'n' }, '<Left>', ':vertical resize +2<CR>')
vim.keymap.set({ 'n' }, '<Down>', ':resize -2<CR>')
vim.keymap.set({ 'n' }, '<Up>', ':resize +2<CR>')

vim.keymap.set({ 'n' }, '<Leader><TAB>', '<C-w><C-w>')
vim.keymap.set({ 'n' }, '<leader>sh', '<C-w>t<C-w>K<CR>')
vim.keymap.set({ 'n' }, '<leader>sv', '<C-w>t<C-w>H<CR>')

-- https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
vim.keymap.set({ 'x' }, '<', '<gv')
vim.keymap.set({ 'x' }, '>', '>gv')

-- new file in current directory
vim.keymap.set(
	{ 'n' },
	'<Leader>n',
	[[:e <C-R>=expand("%:p:h") . "/" <CR>]],
	{ desc = 'Create [n]ew file in CWD' }
)

vim.keymap.set({ 'n' }, '<Leader>p', [[:t.<left><left>]])
vim.keymap.set(
	{ 'n' },
	'<leader>e',
	[[:exe getline(line('.'))<cr>]],
	{ desc = '[E]xecute current line' }
)

-- qq to record, Q to replay
vim.keymap.set({ 'n' }, 'Q', '@@', { desc = 'Replay [Q] macro' })

-- Make dot work in visual mode
vim.keymap.set({ 'v' }, '.', ':norm.<CR>', { desc = 'Repeat in visual mode' })

-- For neovim terminal :term
-- nnoremap <leader>t  :vsplit +terminal<cr>
vim.keymap.set(
	{ 't' },
	'<Esc>',
	[[&filetype == 'fzf' ? "\<esc>" : "\<c-\>\<c-n>"]],
	{ expr = true }
)

vim.keymap.set({ 't' }, '<M-h>', '<c-><c-n><c-w>h')
vim.keymap.set({ 't' }, '<M-j>', '<c-><c-n><c-w>j')
vim.keymap.set({ 't' }, '<M-k>', '<c-><c-n><c-w>k')
vim.keymap.set({ 't' }, '<M-l>', '<c-><c-n><c-w>l')

au.augroup('__MyTerm__', {
	{
		event = 'TermOpen',
		pattern = '*',
		command = 'setl nonumber norelativenumber',
	},
	{ event = 'TermOpen', pattern = 'term://*', command = 'startinsert' },
	{ event = 'TermClose', pattern = 'term://*', command = 'stopinsert' },
})

vim.keymap.set({ 'n' }, '<Localleader> g', function()
	local result = vim.treesitter.get_captures_at_cursor(0)
	print(vim.inspect(result))
end, { desc = 'Show treesitter capture group for textobject under cursor.' })

-- maintain the same shortcut as vim-gtfo becasue it's in my muscle memory.
vim.keymap.set({ 'n' }, 'gof', function()
	vim.ui.open(vim.fn.expand '%:p:h:~')
end, {
	silent = true,
	desc = '[G]o [o]pen [f]older',
})

-- Allows you to visually select a section and then hit @ to run a macro on all lines
-- https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db#.3dcn9prw6
vim.cmd [[function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction]]

vim.keymap.set(
	{ 'x' },
	'@',
	':<C-u>call ExecuteMacroOverVisualRange()<CR>',
	{ desc = 'Execute macro over visual range' }
)

-- Quick note taking per project
vim.keymap.set(
	{ 'n' },
	'<Localleader>t',
	':tab drop .git/todo.md<CR>',
	{ remap = true, desc = 'Add project [t]odos' }
)

-- More easier increment/decrement mappings
vim.keymap.set({ 'n' }, '+', '<C-a>')
vim.keymap.set({ 'n' }, '_', '<C-x>')
vim.keymap.set({ 'x' }, '+', 'g<C-a>')
vim.keymap.set({ 'x' }, '_', 'g<C-x>')

-- Execute "q" macro over visual line selections
vim.keymap.set({ 'x' }, 'Q', [[:'<,'>:normal @q<CR>]])

-- Use / to search inside a visual selection
vim.keymap.set('x', '/', '<Esc>/\\%V')

vim.keymap.set(
	'n',
	'<Esc>',
	vim.g.LoupeLoaded == 1 and '<Plug>(LoupeClearHighlight)'
		or '<cmd>nohlsearch<CR>',
	{ remap = true, desc = 'Clear Search highlight' }
)

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>ld', function()
	vim.diagnostic.open_float(nil, {
		focusable = false,
		source = 'if_many',
	})
end, { desc = 'Show diagnostic [E]rror messages' })

vim.keymap.set(
	'n',
	'<leader>q',
	vim.diagnostic.setloclist,
	{ desc = 'Open diagnostic [Q]uickfix list' }
)
