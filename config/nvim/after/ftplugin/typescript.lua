vim.opt_local.isfname:append '@-@'

local yarn_lock = vim.fn.findfile('yarn.lock', vim.fn.expand '%:p' .. ';')
local pnpm_lock = vim.fn.findfile('pnpm-lock.yaml', vim.fn.expand '%:p' .. ';')

if vim.fn.filereadable(yarn_lock) == 1 then
	vim.bo.makeprg = 'yarn'
elseif vim.fn.filereadable(pnpm_lock) == 1 then
	vim.bo.makeprg = 'pnpm'
else
	vim.bo.makeprg = 'npm'
end
