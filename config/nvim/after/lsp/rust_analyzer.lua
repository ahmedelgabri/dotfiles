return {
	settings = {
		['rust-analyzer'] = {
			imports = {
				granularity = {
					group = 'module',
				},
				prefix = 'self',
			},
			cargo = {
				allFeatures = true,
				buildScripts = {
					enable = true,
				},
			},
			procMacro = {
				enable = true,
			},
			checkOnSave = {
				-- default: `cargo check`
				command = 'clippy',
				allFeatures = true,
			},
			assist = {
				importEnforceGranularity = true,
				importPrefix = 'create',
			},
			inlayHints = {
				lifetimeElisionHints = {
					enable = true,
					useParameterNames = true,
				},
			},
		},
	},
}
