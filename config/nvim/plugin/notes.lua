local notes = require '_.notes'

__.notes = {
	get_notes_completion = notes.get_notes_completion,
}

-- https://vimways.org/2019/personal-notetaking-in-vim/
-- https://danishpraka.sh/2020/02/23/journaling-in-vim.html

vim.api.nvim_create_user_command(
	'ONote',
	function(o)
		notes.note_in_obsidian(o.fargs)
	end,
	{ nargs = '*', complete = 'customlist,v:lua.__.notes.get_notes_completion' }
)

vim.api.nvim_create_user_command('Notes', function(o)
	notes.search_notes(o.args, o.bang)
end, { nargs = '*', bang = true })

vim.keymap.set(
	{ 'n' },
	'<leader>zn',
	":ZkNew {dir = vim.fn.input('Target dir: '), title = vim.fn.input('Title: ') }<CR>"
)

vim.keymap.set({ 'n' }, '<leader>sn', ':Notes<CR>', { silent = true })
vim.keymap.set({ 'n' }, '<localleader>o', function()
	notes.open_in_obsidian()
end, { silent = true })
