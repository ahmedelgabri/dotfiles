if vim.api.nvim_get_option_value('diff', { win = 0 }) then
	vim.cmd.syntax 'off'
	vim.opt_local.number = true
else
	vim.cmd.syntax 'on'
	vim.opt_local.number = false
end
