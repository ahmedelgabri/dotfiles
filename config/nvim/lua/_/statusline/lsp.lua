local M = {}

---@return string?
function M.diagnostics()
	local status = vim.diagnostic.status(0)

	if status == '' then
		return nil
	end

	return '‹› ' .. status
end

---@return string?
function M.progress()
	local clients = vim.lsp.get_clients { bufnr = 0 }
	if #clients == 0 then
		return nil
	end

	local ok, mini_icons = pcall(require, 'mini.icons')
	local icon = ok and mini_icons.get('lsp', 'event') or '󰒋'

	return string.format('%%#Comment#%s%%*', icon)
end

return M
