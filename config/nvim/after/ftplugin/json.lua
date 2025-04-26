if vim.fn.executable 'jq' == 1 then
	vim.bo.formatprg = 'jq .'
else
	vim.bo.formatprg = 'python -m json.tool'
end
