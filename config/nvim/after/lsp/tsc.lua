return {
	settings = {
		['js/ts'] = {
			-- nvim-lspconfig turns both lenses on and settings are deep-merged,
			-- so each one has to be turned off explicitly.
			referencesCodeLens = { enabled = false },
			implementationsCodeLens = { enabled = false },
		},
	},
}
