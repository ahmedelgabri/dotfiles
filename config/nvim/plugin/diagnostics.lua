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

		return orig(bufnr, opts)
	end
end)(vim.diagnostic.open_float)

local clean_src_names = {
	['Lua Diagnostics.'] = 'lua',
	['Lua Syntax Check.'] = 'lua',
}

vim.diagnostic.config {
	jump = {
		on_jump = function(diagnostic, bufnr)
			if diagnostic == nil then
				return
			end

			vim.diagnostic.open_float(bufnr, { scope = 'cursor' })
		end,
	},
	severity_sort = true,
	status = {
		format = function(counts)
			local levels = {
				{ vim.diagnostic.severity.ERROR, 'error', 'DiagnosticSignError' },
				{ vim.diagnostic.severity.WARN, 'warn', 'DiagnosticSignWarn' },
				{ vim.diagnostic.severity.INFO, 'info', 'DiagnosticSignInfo' },
				{ vim.diagnostic.severity.HINT, 'hint', 'DiagnosticSignHint' },
			}
			local parts = {}

			for _, item in ipairs(levels) do
				local severity, icon_name, highlight = item[1], item[2], item[3]
				local count = counts[severity]

				if count ~= nil and count > 0 then
					table.insert(
						parts,
						string.format(
							'%%#%s#%s%s%%*',
							highlight,
							utils.get_icon(icon_name),
							count
						)
					)
				end
			end

			return table.concat(parts, ' ')
		end,
	},
	virtual_text = {
		spacing = 0,
		prefix = function(diag, _, total)
			local icon =
				utils.get_icon(vim.diagnostic.severity[diag.severity]:lower())

			return total > 1 and ' ' .. icon or icon
		end,
		format = function(_)
			return ''
		end,
	},
	float = {
		source = false, -- I handle this in the custom format
		header = '',
		suffix = '',
		prefix = function(diag, _, _)
			local level = vim.diagnostic.severity[diag.severity]
			local icon = utils.get_icon(level:lower())
			local prefix = string.format(' %s ', icon)

			return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
		end,
		format = function(diag)
			local msg = string.format(
				'[%s] %s',
				(clean_src_names[diag.source] or diag.source or '')
					.. (diag.code and ' -> ' .. diag.code or ''),
				diag.message
			)

			return msg
		end,
	},
	signs = false,
}
