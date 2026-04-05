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

	local ok, mini_icons = pcall(require, 'mini.icons')
	local icon = ok and mini_icons.get('lsp', 'event') or '󰒋'
	local hl = 'Comment'

	if #clients == 0 then
		hl = 'ErrorMsg'
	elseif next(__.statusline.lsp_progress) then
		hl = 'DiagnosticWarn'
	end

	return string.format('%%#%s#%s%%*', hl, icon)
end

return M
