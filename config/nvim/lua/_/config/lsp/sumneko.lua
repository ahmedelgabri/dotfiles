return require('lua-dev').setup {
	lspconfig = {
		settings = {
			Lua = {
				diagnostics = {
					globals = {
						'vim',
						'describe',
						'it',
						'before_each',
						'after_each',
						'pending',
						'teardown',
						'packer_plugins',
						'spoon',
						'hs',
					},
				},
				workspace = {
					maxPreload = 2000,
					preloadFileSize = 2000,
					library = {
						['/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/'] = true,
					},
				},
				completion = { keywordSnippet = 'Replace', callSnippet = 'Replace' },
				telemetry = { enable = false },
			},
		},
	},
}
