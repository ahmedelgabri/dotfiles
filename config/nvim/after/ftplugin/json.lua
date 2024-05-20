if vim.fn.executable 'jq' == 1 then
	vim.opt.formatprg = 'jq .'
else
	vim.opt.formatprg = 'python -m json.tool'
end
