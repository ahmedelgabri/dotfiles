-- Plugin mappings are inside plugin/after/<plugin name>.vim files
-- Allows you to visually select a section and then hit @ to run a macro on all lines
-- https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db#.3dcn9prw6
vim.cmd [[function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction]]

local mode_keymaps = {
	['n'] = {
		-- From https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
		-- The `zzzv` keeps search matches in the middle of the window.
		-- and make sure n will go forward when searching with ? or #
		-- https://vi.stackexchange.com/a/2366/4600
		{
			modes = { 'n' },
			action = [[(v:searchforward ? 'n' : 'N') . 'zzzv']],
			opts = { expr = true },
		},
	},
	['N'] = {
		{
			modes = { 'n' },
			action = [[(v:searchforward ? 'N' : 'n') . 'zzzv']],
			opts = { expr = true },
		},
	},
	-- Center { & } movements
	['{'] = { { modes = { 'n' }, action = '{zz' } },
	['}'] = { { modes = { 'n' }, action = '}zz' } },
	['gV'] = {
		{
			modes = { 'n' },
			action = [[`[v`]']],
			opts = { desc = 'Highlight last insert' },
		},
	},

	-- Move by 'display lines' rather than 'logical lines' if no v:count was
	-- provided.  When a v:count is provided, move by logical lines.
	['j'] = {
		{
			modes = { 'n', 'x' },
			action = [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj']],
			opts = { expr = true, desc = 'Move down by display line' },
		},
	},
	['k'] = {
		{
			modes = { 'n', 'x' },
			action = [[v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk']],
			opts = { expr = true, desc = 'Move up by display line' },
		},
	},

	['Y'] = {
		-- Make `Y` behave like `C` and `D` (to the end of line)
		{
			modes = { 'n' },
			action = 'y$',
			opts = { desc = '[Y]ank till end of line' },
		},
	},
	-- Disable arrow keys in insert mode
	-- Use arrow keys to resize the viewports in normal mode
	['<up>'] = {
		{ modes = { 'i' }, action = '<nop>', opts = { remap = true } },
		{
			modes = { 'n' },
			action = ':resize +2<CR>',
			opts = { desc = 'Increase height' },
		},
	},
	['<down>'] = {
		{ modes = { 'i' }, action = '<nop>', opts = { remap = true } },
		{
			modes = { 'n' },
			action = ':resize -2<CR>',
			opts = { desc = 'Decrease height' },
		},
	},
	['<left>'] = {
		{ modes = { 'i' }, action = '<nop>', opts = { remap = true } },
		{
			modes = { 'n' },
			action = ':vertical resize +2<CR>',
			opts = { desc = 'Increase width' },
		},
	},
	['<right>'] = {
		{ modes = { 'i' }, action = '<nop>', opts = { remap = true } },
		{
			modes = { 'n' },
			action = ':vertical resize -2<CR>',
			opts = { desc = 'Decrease width' },
		},
	},

	['<Leader><TAB>'] = { { modes = { 'n' }, action = '<C-w><C-w>' } },

	-- https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
	['<'] = { { modes = { 'x' }, action = '<gv' } },
	['>'] = { { modes = { 'x' }, action = '>gv' } },

	['<leader>e'] = {
		{
			modes = { 'n' },
			action = [[:exe getline(line('.'))<cr>]],
			opts = { desc = '[E]xecute current line' },
		},
	},

	['Q'] = {
		{
			modes = { 'n' },
			action = '@@',
			opts = { desc = 'Replay [Q] macro' },
		},
		{
			modes = { 'x' },
			action = [[:'<,'>:normal @q<CR>]],
			opts = { desc = 'Execute [Q] macro over visual lines' },
		},
	},

	['.'] = {
		{
			modes = { 'v' },
			action = ':norm.<CR>',
			opts = { desc = 'Repeat in visual mode' },
		},
	},

	['<Esc>'] = {
		{
			modes = { 't' },
			action = [[&filetype == 'fzf' ? "\<esc>" : "\<c-\>\<c-n>"]],
			opts = { expr = true, desc = 'Exit terminal mode' },
		},
		{
			modes = { 'n' },
			action = vim.g.LoupeLoaded == 1 and '<Plug>(LoupeClearHighlight)'
				or '<cmd>nohlsearch<CR>',
			opts = { remap = true, desc = 'Clear Search highlight' },
		},
	},

	['<M-h>'] = { { modes = { 't' }, action = '<c-><c-n><c-w>h' } },
	['<M-j>'] = { { modes = { 't' }, action = '<c-><c-n><c-w>j' } },
	['<M-k>'] = { { modes = { 't' }, action = '<c-><c-n><c-w>k' } },
	['<M-l>'] = { { modes = { 't' }, action = '<c-><c-n><c-w>l' } },

	['<Localleader>g'] = {
		{
			modes = { 'n' },
			action = function()
				local result = vim.treesitter.get_captures_at_cursor(0)
				print(vim.inspect(result))
			end,
			opts = {
				desc = 'Show treesitter capture group for textobject under cursor.',
			},
		},
	},
	['gof'] = {
		{
			modes = { 'n' },
			action = function()
				vim.ui.open(vim.fn.expand '%:p:h:~')
			end,
			opts = { silent = true, desc = '[G]o [o]pen [f]older' },
		},
	},

	['@'] = {
		{
			modes = { 'x' },
			action = ':<C-u>call ExecuteMacroOverVisualRange()<CR>',
			opts = { desc = 'Execute macro over visual range' },
		},
	},

	['<Localleader>t'] = {
		{
			-- Quick note taking per project
			modes = { 'n' },
			action = ':tab drop .git/todo.md<CR>',
			opts = { remap = true, desc = 'Add project [t]odos' },
		},
	},

	['+'] = {
		{ modes = { 'n' }, action = '<C-a>', opts = { desc = 'Increment' } },
		{ modes = { 'x' }, action = 'g<C-a>', opts = { desc = 'Increment' } },
	},
	['_'] = {
		{ modes = { 'n' }, action = '<C-x>', opts = { desc = 'Decrement' } },
		{ modes = { 'x' }, action = 'g<C-x>', opts = { desc = 'Decrement' } },
	},

	['<leader>ld'] = {
		{
			modes = { 'n' },
			action = function()
				vim.diagnostic.open_float(
					nil,
					{ focusable = false, source = 'if_many' }
				)
			end,
			opts = { desc = 'Show diagnostic [E]rror messages' },
		},
	},

	['<leader>q'] = {
		{
			modes = { 'n' },
			action = vim.diagnostic.setloclist,
			opts = { desc = 'Open diagnostic [Q]uickfix list' },
		},
	},

	['x'] = {
		{
			modes = { 'n' },
			action = '"_x',
			opts = {
				desc = 'delete a character without storing it in the clipboard',
			},
		},
	},
	-- Center movements
	['<C-d>'] = {
		{
			modes = { 'n' },
			action = '<C-d>zz',
		},
	},
	['<C-u>'] = {
		{
			modes = { 'n' },
			action = '<C-u>zz',
		},
	},
}

for key, mappings in pairs(mode_keymaps) do
	for _, map in pairs(mappings) do
		vim.keymap.set(map.modes, key, map.action, map.opts or {})
	end
end
