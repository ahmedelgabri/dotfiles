local utils = require '_.utils'

vim.opt.conceallevel = 0

utils.plaintext()

if vim.fn.executable 'gh' == 1 then
	vim.cmd [[nnoremap <buffer><leader>p :call utils#openMarkdownPreview()<CR>]]
end
