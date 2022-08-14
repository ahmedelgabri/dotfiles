local M = {}

function M.group(name, opts)
	vim.api.nvim_set_hl(0, name, opts)
end

return M
