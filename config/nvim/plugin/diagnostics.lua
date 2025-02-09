local utils = require '_.utils'

-- wrap open_float to inspect diagnostics and use the severity color for border
-- https://neovim.discourse.group/t/lsp-diagnostics-how-and-where-to-retrieve-severity-level-to-customise-border-color/1679
vim.diagnostic.open_float = (function(orig)
	return function(bufnr, options)
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		local opts = options or {}
		-- A more robust solution would check the "scope" value in `opts` to
		-- determine where to get diagnostics from, but if you're only using
		-- this for your own purposes you can make it as simple as you like
		local diagnostics = vim.diagnostic.get(opts.bufnr or 0, { lnum = lnum })
		local max_severity = vim.diagnostic.severity.HINT

		for _, d in ipairs(diagnostics) do
			-- Equality is "less than" based on how the severities are encoded
			if d.severity < max_severity then
				max_severity = d.severity --[[@as integer]]
			end
		end

		local border_color = ({
			[vim.diagnostic.severity.HINT] = 'DiagnosticHint',
			[vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
			[vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
			[vim.diagnostic.severity.ERROR] = 'DiagnosticError',
		})[max_severity]

		opts.border = utils.get_border(border_color)

		orig(bufnr, opts)
	end
end)(vim.diagnostic.open_float)

vim.diagnostic.config {
	severity_sort = true,
	virtual_text = false,
	-- virtual_text = {
	-- 	-- source = 'always',
	-- 	spacing = 2,
	-- 	prefix = '', -- Could be '●', '▎', 'x'
	-- 	format = function(diagnostic)
	-- 		local source = diagnostic.source
	--
	-- 		if source then
	-- 			local icon =
	-- 				utils.get_icon(vim.diagnostic.severity[diagnostic.severity]:lower())
	--
	-- 			return string.format(
	-- 				'%s %s %s',
	-- 				icon,
	-- 				source,
	-- 				'['
	-- 					.. (diagnostic.code ~= nil and diagnostic.code or diagnostic.message)
	-- 					.. ']'
	-- 			)
	-- 		end
	--
	-- 		return string.format('%s ', diagnostic.message)
	-- 	end,
	-- },
	float = {
		source = 'if_many',
		focusable = false,
		prefix = function(diag)
			local level = vim.diagnostic.severity[diag.severity]
			local icon = utils.get_icon(level:lower())
			local prefix = string.format(' %s ', icon)

			return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
		end,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = utils.get_icon 'error',
			[vim.diagnostic.severity.WARN] = utils.get_icon 'warn',
			[vim.diagnostic.severity.HINT] = utils.get_icon 'hint',
			[vim.diagnostic.severity.INFO] = utils.get_icon 'info',
		},
		numhl = {
			[vim.diagnostic.severity.HINT] = 'DiagnosticHint',
			[vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
			[vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
			[vim.diagnostic.severity.ERROR] = 'DiagnosticError',
		},
	},
}
