-- Use the same settings for JS and TS.
local lang_settings = {
	suggest = { completeFunctionCalls = true },
	inlayHints = {
		functionLikeReturnTypes = { enabled = true },
		parameterNames = { enabled = 'literals' },
		variableTypes = { enabled = true },
	},
}

return {
	root_dir = function(_bufnr, on_dir)
		on_dir(
			not vim.fs.root(0, { '.flowconfig', 'deno.json', 'deno.jsonc' })
				and vim.fs.root(0, {
					'tsconfig.json',
					'jsconfig.json',
					'package.json',
					'.git',
					vim.api.nvim_buf_get_name(0),
				})
		)
	end,
	settings = {
		typescript = vim.tbl_deep_extend('force', lang_settings, {
			tsserver = { maxTsServerMemory = 12288 },
		}),
		javascript = lang_settings,
		vtsls = {
			-- Automatically use workspace version of TypeScript lib on startup.
			autoUseWorkspaceTsdk = true,
			experimental = {
				-- Inlay hint truncation.
				maxInlayHintLength = 30,
				-- For completion performance.
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		-- tsserver_file_preferences = {
		-- 	includeCompletionsForModuleExports = true,
		-- 	includeInlayParameterNameHints = 'all',
		-- 	includeInlayParameterNameHintsWhenArgumentMatchesName = true,
		-- 	includeInlayFunctionParameterTypeHints = true,
		-- 	includeInlayVariableTypeHints = true,
		-- 	includeInlayPropertyDeclarationTypeHints = true,
		-- 	includeInlayFunctionLikeReturnTypeHints = true,
		-- 	includeInlayEnumMemberValueHints = true,
		-- },
	},
}
