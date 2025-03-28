local utils = require '_.utils'

local capabilities = vim.lsp.protocol.make_client_capabilities()

if pcall(require, 'blink.cmp') then
	capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
end

local shared = {
	capabilities = vim.tbl_deep_extend('force', capabilities, {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
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
	}),
	flags = {
		debounce_text_changes = 150,
	},
}

return {
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
					nls.builtins.diagnostics.zsh,
					nls.builtins.diagnostics.hadolint,
					nls.builtins.diagnostics.statix,
					nls.builtins.diagnostics.selene,
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
		dependencies = {
			{ 'https://github.com/Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
		},
		ft = 'lua',
		enabled = function(root_dir)
			return (vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled)
				-- disable when a .luarc.json file is found
				or not vim.uv.fs_stat(root_dir .. '/.luarc.json')
		end,
		opts = {
			library = {
				{
					path = vim.env.HOME
						.. '/.hammerspoon/Spoons/EmmyLua.spoon/annotations',
					words = { 'hs' },
				},
				-- Only load luvit types when the `vim.uv` word is found
				{ path = 'luvit-meta/library', words = { 'vim%.uv' } },
				{ path = 'snacks.nvim', words = { 'Snacks' } },
			},
		},
	},
	{
		'https://github.com/zk-org/zk-nvim',
		ft = { 'markdown' },
		config = function()
			require('zk').setup {
				picker = 'fzf_lua',
				lsp = {
					-- `config` is passed to `vim.lsp.start_client(config)`
					config = vim.tbl_deep_extend('force', shared, {}),
				},
			}

			-- local cmds = require 'zk.commands'
		end,
	},
	{ 'https://github.com/b0o/SchemaStore.nvim' },
	{
		'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
		event = 'LspAttach',
		opts = {
			preset = 'nonerdfont',
			options = {
				show_source = true,
				multiple_diag_under_cursor = true,
				softwrap = 80,
			},
		},
	},
	{
		'https://github.com/neovim/nvim-lspconfig',
		event = utils.LazyFile,
		config = function()
			-- for debugging
			-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
			-- :lua print(vim.lsp.get_log_path())
			-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

			-- require('vim.lsp.log').set_level 'debug'
			-- require('vim.lsp.log').set_format_func(vim.inspect)
			local au = require '_.utils.au'
			local map_opts = { buffer = true, silent = true }

			-- Globally override borders
			-- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#borders
			local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview

			---@diagnostic disable-next-line: duplicate-set-field
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or utils.get_border()
				return orig_util_open_floating_preview(contents, syntax, opts, ...)
			end

			local configs = require 'lspconfig.configs'
			local util = require 'lspconfig.util'

			configs.oxc_language_server = {
				default_config = {
					cmd = { utils.get_lsp_bin 'oxc_language_server' },
					filetypes = {
						'javascript',
						'javascript.jsx',
						'javascriptreact',
						'typescript',
						'typescript.tsx',
						'typescriptreact',
					},
					root_dir = util.root_pattern '.oxlintrc.json',
					single_file_support = false,
					settings = {
						['enable'] = true,
						['run'] = 'onType',
						['config'] = '.oxlintrc.json',
					},
				},
			}

			au.autocmd {
				event = 'LspAttach',
				desc = 'LSP actions',
				callback = function(event)
					local bufnr = event.buf
					local client = assert(
						vim.lsp.get_client_by_id(event.data.client_id),
						'must have valid client'
					)

					-- ---------------
					-- GENERAL
					-- ---------------
					client.flags.allow_incremental_sync = true

					-- ---------------
					-- MAPPINGS
					-- ---------------
					for _, item in ipairs {
						{
							{ 'n' },
							'<C-]>',
							function()
								require('fzf-lua').lsp_definitions {
									-- https://github.com/ibhagwan/fzf-lua/wiki#lsp-jump-to-location-for-single-result
									jump1 = true,
								}
							end,
							{ desc = 'Go to Definition' },
						},
						{
							{ 'n' },
							'<leader>a',
							function()
								require('fzf-lua').lsp_code_actions {}
							end,
							{ desc = 'Code [A]ctions' },
						},
						{
							{ 'n' },
							'<leader>f',
							function()
								require('fzf-lua').lsp_references {
									-- https://github.com/ibhagwan/fzf-lua/wiki#lsp-references-ignore-current-line
									ignore_current_line = true,
									-- https://github.com/ibhagwan/fzf-lua/wiki#lsp-references-ignore-declaration
									-- includeDeclaration = false
								}
							end,
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
							function()
								require('fzf-lua').lsp_declarations {}
							end,
							{ desc = 'Go to [D]eclaration' },
						},
						{
							{ 'n' },
							'<leader>i',
							function()
								require('fzf-lua').lsp_implementations {}
							end,
							{ desc = 'Go to [I]mplementation' },
						},
						{
							{ 'n' },
							'<leader>dq',
							vim.diagnostic.setloclist,
							{ desc = 'Open diagnostics list' },
						},
					} do
						local extra_opts = table.remove(item, 4)
						local merged_opts = vim.tbl_extend('force', map_opts, extra_opts)

						table.insert(item, 4, merged_opts)

						local modes, lhs, rhs, opts = item[1], item[2], item[3], item[4]

						vim.keymap.set(modes, lhs, rhs, opts)
					end

					-- ---------------
					-- AUTOCMDS
					-- ---------------

					if
						client.supports_method(
							vim.lsp.protocol.Methods.textDocument_documentHighlight
						)
					then
						local group = '__LSP_HIGHLIGHTS__'
						vim.api.nvim_create_augroup(group, {
							clear = false,
						})
						vim.api.nvim_clear_autocmds {
							buffer = bufnr,
							group = group,
						}
						vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.buf.clear_references,
						})
					end

					if
						client.supports_method(
							vim.lsp.protocol.Methods.textDocument_codeLens
						)
					then
						au.augroup('__LSP_CODELENS__', {
							{
								event = { 'CursorHold', 'BufEnter', 'InsertLeave' },
								callback = function()
									vim.lsp.codelens.refresh { bufnr = bufnr }
								end,
								buffer = bufnr,
							},
						})
					end

					if
						client.name == 'gopls'
						and not client.server_capabilities.semanticTokensProvider
					then
						local semantic =
							client.config.capabilities.textDocument.semanticTokens

						client.server_capabilities.semanticTokensProvider = {
							full = true,
							legend = {
								tokenModifiers = semantic.tokenModifiers,
								tokenTypes = semantic.tokenTypes,
							},
							range = true,
						}
					end
				end,
			}

			local web_roots =
				vim.fs.root(0, { 'package.json', '.git', vim.api.nvim_buf_get_name(0) })

			-- Use the same settings for JS and TS.
			local lang_settings = {
				suggest = { completeFunctionCalls = true },
				inlayHints = {
					functionLikeReturnTypes = { enabled = true },
					parameterNames = { enabled = 'literals' },
					variableTypes = { enabled = true },
				},
			}

			local servers = {
				cssls = {
					root_dir = function()
						return web_roots
					end,
				},
				stylelint_lsp = {
					root_dir = function()
						return web_roots
					end,
				},
				html = {
					root_dir = function()
						return web_roots
					end,
				},
				bashls = {},
				dockerls = {},
				docker_compose_language_service = {},
				eslint = {},
				oxc_language_server = {},
				vtsls = {
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
				},
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
				ruff = {
					init_options = {
						settings = {
							configurationPreference = 'filesystemFirst',
							fixAll = true,
							organizeImports = true,
							lint = {
								enable = true,
								preview = true,
							},
							format = {
								preview = true,
							},
						},
					},
				},
				tailwindcss = {},
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
								unusedLocalExclude = { '_*' },
							},
							workspace = {
								ignoreDir = {
									'.direnv',
								},
							},
							completion = {
								keywordSnippet = 'Replace',
								callSnippet = 'Replace',
							},
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
				},
				gopls = {
					cmd = { 'gopls', 'serve' },
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
				nixd = {
					-- https://github.com/nix-community/nixvim/issues/2390#issuecomment-2408101568
					-- offset_encoding = 'utf-8',
					settings = {
						nixd = {
							nixpkgs = {
								expr = vim.fs.root(0, { 'shell.nix' }) ~= nil
										and 'import <nixpkgs> { }'
									or string.format(
										'import (builtins.getFlake "%s").inputs.nixpkgs { }',
										vim.fs.root(0, { 'flake.nix' }) or vim.fn.expand '$DOTFILES'
									),
							},
							formatting = {
								command = { 'alejandra' },
							},
							options = vim.tbl_extend('force', {
								-- home_manager = {
								-- 	expr = string.format(
								-- 		'(builtins.getFlake "%s").homeConfigurations.%s.options',
								-- 		vim.fn.expand '$DOTFILES',
								-- 		vim.fn.hostname()
								-- 	),
								-- },
							}, vim.fn.has 'macunix' and {
								['nix-darwin'] = {
									expr = string.format(
										'(builtins.getFlake "%s").darwinConfigurations.%s.options',
										vim.fn.expand '$DOTFILES',
										vim.fn.hostname()
									),
								},
							} or {
								nixos = {
									expr = string.format(
										'(builtins.getFlake "%s").nixosConfigurations.%s.options',
										vim.fn.expand '$DOTFILES',
										vim.fn.hostname()
									),
								},
							}),
						},
					},
				},
				ast_grep = {
					cmd = { utils.get_lsp_bin 'ast-grep', 'lsp' },
					filetypes = { -- https://ast-grep.github.io/reference/languages.html
						'c',
						'cpp',
						'rust',
						'go',
						'java',
						'python',
						'javascript',
						'typescript',
						'typescriptreact',
						'html',
						'css',
						'kotlin',
						'dart',
						'lua',
					},
				},
				jsonls = {
					settings = {
						json = {
							validate = { enable = true },
							format = { enable = true },
						},
					},
					-- Lazy-load schemas.
					on_new_config = function(config)
						config.settings.json.schemas = config.settings.json.schemas or {}
						vim.list_extend(
							config.settings.json.schemas,
							require('schemastore').json.schemas {}
						)
					end,
				},
				taplo = {
					settings = {
						-- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
						taplo = {
							configFile = { enabled = true },
							schema = {
								enabled = true,
								catalogs = {
									'https://www.schemastore.org/api/json/catalog.json',
								},
								cache = {
									memoryExpiration = 60,
									diskExpiration = 600,
								},
							},
						},
					},
				},
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
	},
}
