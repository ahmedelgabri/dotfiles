vim.cmd [[setlocal conceallevel=2]]
vim.cmd [[setlocal isfname+=@-@ ]]

local yarn_lock = vim.fn.findfile('yarn.lock', vim.fn.expand '%:p' .. ';')
local pnpm_lock = vim.fn.findfile('pnpm-lock.yaml', vim.fn.expand '%:p' .. ';')

if vim.fn.filereadable(yarn_lock) == 1 then
	vim.cmd [[setlocal makeprg=yarn]]
elseif vim.fn.filereadable(pnpm_lock) == 1 then
	vim.cmd [[setlocal makeprg=pnpm]]
else
	vim.cmd [[setlocal makeprg=npm]]
end
