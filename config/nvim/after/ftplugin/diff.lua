if vim.api.nvim_get_option_value('diff', { win = 0 }) then
	vim.cmd.syntax 'off'
	vim.wo.number = true
else
	vim.cmd.syntax 'on'
	vim.wo.number = false
end
