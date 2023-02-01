return function(on_attach)
	local ok, nls = pcall(require, 'null-ls')

	if not ok then
		return
	end

	local h = require 'null-ls.helpers'

	nls.setup {
		debug = true,
		debounce = 150,
		on_attach = on_attach,
		sources = {
			-- nixlinter,
			nls.builtins.diagnostics.shellcheck.with {
				filetypes = { 'sh', 'bash' },
				runtime_condition = h.cache.by_bufnr(function(params)
					-- don't run on .env files, which are also set to sh
					return params.bufname:match '%.env.*' == nil
						or params.bufname:match '%.env' == nil
				end),
			},
			nls.builtins.diagnostics.ruff,
			nls.builtins.diagnostics.hadolint,
			nls.builtins.diagnostics.vint,
			nls.builtins.diagnostics.vale.with {
				filetypes = {
					'asciidoc',
					'markdown',
					'tex',
					'text',
				},
			},
			nls.builtins.diagnostics.statix,
			nls.builtins.diagnostics.dotenv_linter,
		},
	}
end
