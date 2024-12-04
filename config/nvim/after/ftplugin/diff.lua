if vim.api.nvim_get_option_value('diff', { buf = 0 }) then
	vim.cmd [[syntax off]]
	vim.opt.number = true
else
	vim.cmd [[syntax on]]
	vim.opt.number = false
end
