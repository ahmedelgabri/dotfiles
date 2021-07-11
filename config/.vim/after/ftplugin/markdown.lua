vim.opt_local.spell = true
vim.opt_local.linebreak = true
vim.opt_local.list = false

if vim.fn.executable("grip") == 1 then
  vim.cmd [[nnoremap <buffer><leader>p :call utils#openMarkdownPreview()<CR>]]
end

if vim.fn.executable("glow") == 1 then
  vim.cmd [[nnoremap <buffer><leader>g :Glow<CR>]]
end
