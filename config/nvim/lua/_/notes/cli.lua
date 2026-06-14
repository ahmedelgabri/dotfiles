local script = vim.fn.fnamemodify(arg[0], ':p')
local nvim_config =
	vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script))))
vim.opt.runtimepath:prepend(nvim_config)

local args = vim.list_slice(arg, 1)
if args[1] == '--' then
	table.remove(args, 1)
end

require('_.notes.index').run(args)
