local au = require '_.utils.au'
local utils = require '_.utils'
local map_opts = { buffer = true, silent = true }

local capabilities =
	vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), {
		textDocument = {
			completion = {
				completionItem = {
					snippetSupport = true,
					resolveSupport = {
						properties = {
							'documentation',
							'detail',
							'additionalTextEdits',
						},
					},
				},
			},
		},
	})

if pcall(require, 'cmp_nvim_lsp') then
	capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
end

local handlers = {
	[vim.lsp.protocol.Methods.textDocument_hover] = vim.lsp.with(
		vim.lsp.handlers.hover,
		{ focusable = true, silent = true, border = utils.get_border() }
	),
	[vim.lsp.protocol.Methods.textDocument_signatureHelp] = vim.lsp.with(
		vim.lsp.handlers.hover,
		{ focusable = false, silent = true, border = utils.get_border() }
	),
}

local shared = {
	capabilities = capabilities,
	handlers = handlers,
	flags = {
		debounce_text_changes = 150,
	},
}

local mappings = {
	{
		{ 'n' },
		'<leader>a',
		vim.lsp.buf.code_action,
		{ desc = 'Code [A]ctions' },
	},
	{
		{ 'n' },
		'<leader>f',
		vim.lsp.buf.references,
		{ desc = 'Show Re[f]erences' },
	},
	{
		{ 'n' },
		'<leader>r',
		vim.lsp.buf.rename,
		{ desc = '[R]ename Symbol' },
	},
	{
		{ 'n' },
		'<leader>D',
		vim.lsp.buf.declaration,
		{ desc = 'Go to [D]eclaration' },
	},
	{
		{ 'n' },
		'<leader>i',
		vim.lsp.buf.implementation,
		{ desc = 'Go to [I]mplementation' },
	},
}

au.autocmd {
	event = 'LspAttach',
	desc = 'LSP actions',
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)

		if client == nil then
			return
		end

		-- ---------------
		-- GENERAL
		-- ---------------
		client.flags.allow_incremental_sync = true

		-- ---------------
		-- MAPPINGS
		-- ---------------
		for _, item in ipairs(mappings) do
			local extra_opts = table.remove(item, 4)
			local merged_opts = vim.tbl_extend('force', map_opts, extra_opts)

			table.insert(item, 4, merged_opts)

			local modes, lhs, rhs, opts = item[1], item[2], item[3], item[4]

			vim.keymap.set(modes, lhs, rhs, opts)
		end

		-- ---------------
		-- AUTOCMDS
		-- ---------------
		--
		if
			client.supports_method(
				vim.lsp.protocol.Methods.textDocument_documentHighlight
			)
		then
			au.augroup('__LSP_HIGHLIGHTS__', {
				{
					event = { 'CursorHold', 'CursorHoldI' },
					callback = vim.lsp.buf.document_highlight,
					buffer = event.buf,
				},
				{
					event = { 'CursorMoved', 'CursorMovedI' },
					callback = vim.lsp.buf.clear_references,
					buffer = event.buf,
				},
			}, { clear = false })
		end

		if
			client.supports_method(vim.lsp.protocol.Methods.textDocument_codeLens)
		then
			au.augroup('__LSP_CODELENS__', {
				{
					event = { 'CursorHold', 'BufEnter', 'InsertLeave' },
					callback = function()
						vim.lsp.codelens.refresh { bufnr = event.buf }
					end,
					buffer = event.buf,
				},
			})
		end
	end,
}

return {
	'https://github.com/neovim/nvim-lspconfig',
	event = { 'BufReadPre' },
	dependencies = {
		{
			'https://github.com/SmiteshP/nvim-navic',
			event = 'LspAttach',
			init = function()
				vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
			end,
			opts = {
				click = true,
				highlight = true,
				lsp = {
					auto_attach = true,
				},
			},
		},
		{
			'https://github.com/pmizio/typescript-tools.nvim',
			event = {
				'BufReadPost *.ts,*.mts,*.cts,*.tsx,*.js,*.mjs,*.cjs,*.jsx',
				'BufNewFile *.ts,*.mts,*.cts,*.tsx,*.js,*.mjs,*.cjs,*.jsx',
			},
			dependencies = {
				'https://github.com/nvim-lua/plenary.nvim',
			},
			opts = {
				single_file_support = false,
				handlers = shared.handlers,
				root_dir = function()
					return not vim.fs.root(
						0,
						{ '.flowconfig', 'deno.json', 'deno.jsonc' }
					) and vim.fs.root(0, {
						'tsconfig.json',
						'jsconfig.json',
						'package.json',
						'.git',
						vim.api.nvim_buf_get_name(0),
					})
				end,
				settings = {
					tsserver_file_preferences = {
						includeCompletionsForModuleExports = true,
						includeInlayParameterNameHints = 'all',
						includeInlayParameterNameHintsWhenArgumentMatchesName = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
			},
		},
		{
			'https://github.com/nvimtools/none-ls.nvim',
			dependencies = {
				'https://github.com/nvim-lua/plenary.nvim',
			},
			event = 'LspAttach',
			config = function()
				local nls = require 'null-ls'

				nls.setup {
					debug = false,
					debounce = 150,
					sources = {
						-- nixlinter,
						nls.builtins.diagnostics.hadolint,
						nls.builtins.diagnostics.vint,
						nls.builtins.diagnostics.statix,
						nls.builtins.diagnostics.dotenv_linter.with {
							filetypes = { 'dotenv' },
							extra_args = { '--skip', 'UnorderedKey' },
						},
						nls.builtins.diagnostics.actionlint.with {
							condition = function()
								local cwd = vim.fn.expand '%:p:.'
								return cwd:find '.github/'
							end,
						},
					},
				}
			end,
		},
		{
			'https://github.com/folke/trouble.nvim',
			cmd = { 'Trouble' },
			opts = {},
		},
		{
			'https://github.com/folke/lazydev.nvim',
			-- dependencies = {
			-- 	{ 'https://github.com/Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
			-- },
			ft = 'lua',
			opts = {
				library = {
					{ path = 'wezterm-types', mods = { 'wezterm' } },
					{
						path = vim.env.HOME
							.. '/.hammerspoon/Spoons/EmmyLua.spoon/annotations',
						words = { 'hs' },
					},
				},
			},
		},
		{
			'https://github.com/zk-org/zk-nvim',
			event = 'LspAttach',
			config = function()
				require('zk').setup {
					picker = 'fzf_lua',
					lsp = {
						-- `config` is passed to `vim.lsp.start_client(config)`
						config = vim.tbl_deep_extend('force', shared, {
							-- cmd = { 'zk', 'lsp', '--log', '/tmp/zk-lsp.log' },
							cmd = { 'zk', 'lsp' },
							name = 'zk',
							-- root_dir = nvim_lsp.util.path.dirname,
						}),

						auto_attach = {
							enabled = true,
							filetypes = { 'markdown' },
						},
					},
				}

				local cmds = require 'zk.commands'
			end,
		},
		{
			'https://github.com/b0o/SchemaStore.nvim',
		},
	},
	config = function()
		-- for debugging
		-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
		-- :lua print(vim.lsp.get_log_path())
		-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

		-- require('vim.lsp.log').set_level 'debug'
		-- require('vim.lsp.log').set_format_func(vim.inspect)

		local servers = {
			cssls = {},
			html = {},
			bashls = {},
			vimls = {
				init_options = { isNeovim = true },
			},
			dockerls = {},
			clojure_lsp = {},
			eslint = {},
			pyright = {
				settings = {
					pyright = {
						-- Using Ruff's import organizer
						disableOrganizeImports = true,
					},
					python = {
						analysis = {
							-- Ignore all files for analysis to exclusively use Ruff for linting
							ignore = { '*' },
						},
					},
				},
			},
			ruff_lsp = {
				init_options = {
					settings = {},
				},
			},
			-- marksman = {},
			tailwindcss = {
				init_options = {
					userLanguages = {
						eruby = 'erb',
						eelixir = 'html-eex',
						['javascript.jsx'] = 'javascriptreact',
						['typescript.tsx'] = 'typescriptreact',
					},
				},
				handlers = {
					['tailwindcss/getConfiguration'] = function(_, _, context)
						-- tailwindcss lang server waits for this response before providing hover
						vim.lsp.buf_notify(
							context.bufnr,
							'tailwindcss/getConfigurationResponse',
							{ _id = context.params._id }
						)
					end,
				},
			},
			lua_ls = {
				settings = {
					Lua = {
						codeLens = { enable = true },
						hint = {
							enable = true,
							arrayIndex = 'Disable',
						},
						doc = {
							privateName = { '^_' },
						},
						diagnostics = {
							disable = { 'trailing-space' },
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
							unusedLocalExclude = { '_*' },
						},
						workspace = {
							ignoreDir = {
								'.direnv',
							},
						},
						completion = { keywordSnippet = 'Replace', callSnippet = 'Replace' },
						telemetry = { enable = false },
					},
				},
			},
			rust_analyzer = {
				settings = {
					['rust-analyzer'] = {
						imports = {
							granularity = {
								group = 'module',
							},
							prefix = 'self',
						},
						cargo = {
							buildScripts = {
								enable = true,
							},
						},
						procMacro = {
							enable = true,
						},
						checkOnSave = {
							command = 'clippy',
						},
					},
				},
			},
			gopls = {
				cmd = { 'gopls', 'serve' },
				settings = {
					gopls = {
						experimentalPostfixCompletions = true,
						analyses = {
							unusedparams = true,
							shadow = true,
						},
						staticcheck = true,
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
					},
				},
				init_options = {
					usePlaceholders = true,
				},
				root_dir = function()
					return vim.fs.root(
						0,
						{ 'go.mod', '.git', vim.api.nvim_buf_get_name(0) }
					)
				end,
			},
			denols = {
				root_dir = function()
					return vim.fs.root(0, { 'deno.json', 'deno.jsonc' })
				end,
			},
			nil_ls = {},
			ast_grep = {},
			jsonls = {
				filetypes = { 'json', 'jsonc' },
				settings = {
					json = {
						schemas = require('schemastore').json.schemas {},
						validate = { enable = true },
					},
				},
			},
			-- TOML
			taplo = {},
			yamlls = {
				settings = {
					yaml = {
						schemaStore = {
							-- You must disable built-in schemaStore support if you want to use
							-- this plugin and its advanced options like `ignore`.
							enable = false,
							-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
							url = '',
						},
						-- Schemas https://www.schemastore.org
						schemas = require('schemastore').yaml.schemas {
							-- ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = {
							-- 	'docker-compose*.{yml,yaml}',
							-- },
						},
					},
				},
			},
			typos_lsp = {
				cmd_env = { RUST_LOG = 'error' },
				init_options = {
					-- Custom config. Used together with a config file found in the workspace or its parents,
					-- taking precedence for settings declared in both.
					-- Equivalent to the typos `--config` cli argument.
					-- config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
					-- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
					-- Defaults to error.
					diagnosticSeverity = 'Error',
				},
			},
		}

		for server, config in pairs(servers) do
			local server_disabled = (config.disabled ~= nil and config.disabled)
				or false

			if not server_disabled then
				require('lspconfig')[server].setup(
					vim.tbl_deep_extend('force', shared, config)
				)
			end
		end
	end,
}
