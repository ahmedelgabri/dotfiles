local utils = require '_.utils'

vim.opt.conceallevel = 2

utils.plaintext()

if vim.fn.executable 'gh' == 1 then
	vim.cmd [[nnoremap <buffer><leader>p :call utils#openMarkdownPreview()<CR>]]
end

if vim.fn.executable 'glow' == 1 then
	vim.cmd [[nnoremap <buffer><leader>g :Glow<CR>]]
end
