if vim.fn.exists 'g:loaded_eunuch' == 0 then
	return
end

-- This command & mapping shadows the ones in mappings.vim
-- if the plugin is available then use the plugin, if not fallback to the other one.

-- Move is more flexiabile thatn Rename
-- https://www.youtube.com/watch?v=Av2pDIY7nRY
vim.keymap.set(
	{ 'n' },
	'<leader>m',
	':Move <C-R>=expand("%")<cr>',
	{ remap = true }
)
