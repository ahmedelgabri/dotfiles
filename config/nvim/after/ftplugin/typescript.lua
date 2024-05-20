vim.opt_local.conceallevel = 2
vim.opt_local.isfname:append '@-@'

local yarn_lock = vim.fn.findfile('yarn.lock', vim.fn.expand '%:p' .. ';')
local pnpm_lock = vim.fn.findfile('pnpm-lock.yaml', vim.fn.expand '%:p' .. ';')

if vim.fn.filereadable(yarn_lock) == 1 then
	vim.opt_local.makeprg = 'yarn'
elseif vim.fn.filereadable(pnpm_lock) == 1 then
	vim.opt_local.makeprg = 'pnpm'
else
	vim.opt_local.makeprg = 'npm'
end
