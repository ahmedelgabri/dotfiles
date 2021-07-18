-- Make these commonly mistyped commands still work
vim.cmd [[command! WQ wq]]
vim.cmd [[command! Wq wq]]
vim.cmd [[command! Wqa wqa]]
vim.cmd [[command! W w]]
vim.cmd [[command! Q q]]

vim.cmd [[command! Light set background=light]]
vim.cmd [[command! Dark set background=dark]]

-- Delete the current file and clear the buffer
if vim.fn.exists ':Delete' then
  vim.cmd [[command! Del :Delete]]
else
  vim.cmd [[command! Del :call delete(@%) | bdelete!]]
end

vim.cmd [[command! ClearRegisters call utils#ClearRegisters()]]
