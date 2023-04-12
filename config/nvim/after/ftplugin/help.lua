vim.cmd [[wincmd L]]
vim.cmd [[nmap <buffer> K K]]

if vim.fn.has 'nvim-0.9' > 0 then
	vim.treesitter.start()
end
