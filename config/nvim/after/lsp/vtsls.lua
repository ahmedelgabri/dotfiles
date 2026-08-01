local utils = require '_.utils'

local ts_root = utils.root_for(
	{ 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
	{ with_buf_name = true }
)

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
	root_dir = function(bufnr, on_dir)
		-- Don't attach if this is a Deno or Flow project
		if vim.fs.root(0, { '.flowconfig', 'deno.json', 'deno.jsonc' }) then
			return
		end

		ts_root(bufnr, on_dir)
	end,
	settings = {
		typescript = vim.tbl_deep_extend('force', lang_settings, {
			tsserver = {
				maxTsServerMemory = 12288,
				watchOptions = {
					watchFile = 'useFsEvents',
					watchDirectory = 'useFsEvents',
				},
			},
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
