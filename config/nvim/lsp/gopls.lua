return {
	settings = {
		gopls = {
			experimentalPostfixCompletions = true,
			analyses = {
				unusedparams = true,
				shadow = true,

				fieldalignment = false, -- find structs that would use less memory if their fields were sorted
				nilness = true,
				unusedwrite = true,
				useany = true,
			},
			-- DISABLED: staticcheck
			--
			-- gopls doesn't invoke the staticcheck binary.
			-- Instead it imports the analyzers directly.
			-- This means it can report on issues the binary can't.
			-- But it's not a good thing (like it initially sounds).
			-- You can't then use line directives to ignore issues.
			--
			-- Instead of using staticcheck via gopls.
			-- We have golangci-lint execute it instead.
			--
			-- For more details:
			-- https://github.com/golang/go/issues/36373#issuecomment-570643870
			-- https://github.com/golangci/golangci-lint/issues/741#issuecomment-1488116634
			--
			-- staticcheck = true,
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			codelenses = {
				gc_details = false,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			gofumpt = true,
			semanticTokens = true,
			usePlaceholders = true,
		},
	},
	init_options = {
		usePlaceholders = true,
	},
	root_dir = function(_bufnr, on_dir)
		on_dir(vim.fs.root(0, { 'go.mod', '.git', vim.api.nvim_buf_get_name(0) }))
	end,
}
