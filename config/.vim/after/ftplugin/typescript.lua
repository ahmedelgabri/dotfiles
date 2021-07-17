vim.cmd [[setlocal conceallevel=2]]
vim.cmd [[setlocal isfname+=@-@ ]]

local package_lock = vim.fn.findfile(
  'package-lock.json',
  vim.fn.expand '%:p' .. ';'
)

if vim.fn.filereadable(package_lock) == 1 then
  vim.cmd [[setlocal makeprg=npm]]
else
  vim.cmd [[setlocal makeprg=yarn]]
end
