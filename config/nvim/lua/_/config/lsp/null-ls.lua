return function(on_attach)
	local ok, nls = pcall(require, 'null-ls')

	if not ok then
		return
	end

	local h = require 'null-ls.helpers'

	-- local nixlinter = {
	--   method = nls.methods.DIAGNOSTICS,
	--   filetypes = { 'nix' },
	--   generator = nls.generator {
	--     command = 'nix-linter',
	--     args = { '--json', '-' },
	--     to_stdin = true,
	--     from_stderr = true,
	--     -- choose an output format (raw, json, or line)
	--     format = 'json',
	--     check_exit_code = function(code)
	--       return code <= 1
	--     end,
	--     on_output = function(params)
	--       local diags = {}
	--       for _, d in ipairs(params.output) do
	--         table.insert(diags, {
	--           row = d.pos.spanBegin.sourceLine,
	--           col = d.pos.spanBegin.sourceColumn,
	--           end_col = d.pos.spanEnd.sourceColumn,
	--           code = d.offending,
	--           message = d.description,
	--           severity = 1,
	--         })
	--       end
	--       return diags
	--     end,
	--     -- on_output = h.diagnostics.from_pattern {
	--     --   {
	--     --     pattern = [[ (.*) at (\.\/.*):(\d+):(\d+)]],
	--     --     groups = { 'message', 'file', 'row', 'col' },
	--     --   },
	--     -- },
	--   },
	-- }

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
