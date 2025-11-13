return {
	settings = {
		basedpyright = {
			analysis = {
				-- Ignore all files for analysis to exclusively use Ruff for linting
				typeCheckingMode = 'basic',
				ignore = { '*' },
			},
		},
	},
}
