return function(on_attach)
	local ok, nls = pcall(require, 'null-ls')

	if not ok then
		return
	end

	nls.setup {
		debug = true,
		debounce = 150,
		on_attach = on_attach,
		sources = {
			-- nixlinter,
			nls.builtins.diagnostics.shellcheck.with {
				filetypes = { 'sh', 'bash' },
			},
			nls.builtins.diagnostics.pylint,
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
		},
	}
end
