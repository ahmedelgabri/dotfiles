vim.cmd [[setlocal spell]]
vim.cmd [[setlocal linebreak]]
vim.cmd [[setlocal nolist]]

if vim.fn.executable 'grip' == 1 then
  vim.cmd [[nnoremap <buffer><leader>p :call utils#openMarkdownPreview()<CR>]]
end

if vim.fn.executable 'glow' == 1 then
  vim.cmd [[nnoremap <buffer><leader>g :Glow<CR>]]
end
