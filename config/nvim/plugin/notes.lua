local notes = require '_.notes'

-- https://vimways.org/2019/personal-notetaking-in-vim/
-- https://danishpraka.sh/2020/02/23/journaling-in-vim.html

vim.api.nvim_create_user_command('ONote', function(o)
	notes.note_in_obsidian(o.fargs)
end, { nargs = '*', complete = notes.get_notes_completion })

vim.api.nvim_create_user_command('Notes', function(o)
	require('snacks').picker.grep {
		search = o.args or '',
		-- search = o.args,
		dirs = { notes.get_dir() },
		-- winopts = { fullscreen = o.bang },
	}
end, { nargs = '*', bang = true })

vim.keymap.set(
	{ 'n' },
	'<localleader>zn',
	":ZkNew {dir = vim.fn.input('Target dir: '), title = vim.fn.input('Title: ') }<CR>",
	{ desc = 'Create new ZK note' }
)

vim.keymap.set(
	{ 'n' },
	'<localleader>sn',
	':Notes<CR>',
	{ silent = true, desc = '[S]earch [N]otes' }
)
vim.keymap.set({ 'n' }, '<localleader>o', function()
	notes.open_in_obsidian()
end, { silent = true, desc = '[O]pen in Obsidian' })
