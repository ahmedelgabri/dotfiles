vim.opt_local.conceallevel = 2
vim.cmd [[setl isfname+=@-@ ]]

local package_lock =
  vim.fn.findfile("package-lock.json", vim.fn.expand("%:p") .. ";")

if vim.fn.filereadable(package_lock) == 1 then
  vim.opt_local.makeprg = "npm"
else
  vim.opt_local.makeprg = "yarn"
end
