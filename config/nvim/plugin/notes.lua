require '_.notes'

-- https://vimways.org/2019/personal-notetaking-in-vim/
-- https://danishpraka.sh/2020/02/23/journaling-in-vim.html

vim.api.nvim_create_user_command(
	'ONote',
	[[call v:lua.__.notes.note_in_obsidian(<f-args>)]],
	{ nargs = '*', complete = 'customlist,v:lua.__.notes.get_notes_completion' }
)

vim.api.nvim_create_user_command(
	'Notes',
	[[call v:lua.__.notes.search_notes(<q-args>, <bang>0)]],
	{ nargs = '*', bang = true }
)

vim.keymap.set(
	{ 'n' },
	'<leader>zn',
	":ZkNew {dir = vim.fn.input('Target dir: '), title = vim.fn.input('Title: ') }<CR>"
)

vim.keymap.set({ 'n' }, '<leader>sn', ':Notes<CR>', { silent = true })
vim.keymap.set(
	{ 'n' },
	'<localleader>o',
	':call v:lua.__.notes.open_in_obsidian()<CR>',
	{ silent = true }
)
