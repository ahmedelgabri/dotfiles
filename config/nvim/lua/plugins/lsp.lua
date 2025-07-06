local utils = require '_.utils'

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
	{ 'https://github.com/b0o/SchemaStore.nvim' },
	{
		'https://github.com/neovim/nvim-lspconfig',
		event = 'VeryLazy',
		config = function()
			-- for debugging
			-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
			-- :lua print(vim.lsp.get_log_path())
			-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

			-- require('vim.lsp.log').set_level 'debug'
			-- require('vim.lsp.log').set_format_func(vim.inspect)
			local au = require '_.utils.au'
			local map_opts = { buffer = true, silent = true }
			local web_roots = function(_bufnr, on_dir)
				on_dir(
					vim.fs.root(
						0,
						{ 'package.json', '.git', vim.api.nvim_buf_get_name(0) }
					)
				)
			end

			vim.lsp.config('*', {
				capabilities = {
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
				},
				flags = {
					debounce_text_changes = 150,
				},
				root_markers = { '.git' },
			})

			vim.lsp.config('cssls', {
				root_dir = web_roots,
			})

			vim.lsp.config('stylelint_lsp', {
				root_dir = web_roots,
			})

			vim.lsp.config('html', {
				root_dir = web_roots,
			})

			vim.lsp.config('pyright', {
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
			})

			vim.lsp.config('ruff', {
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
			})

			-- https://github.com/wincent/wincent/blob/5ab9e1fbe302b1a5948eb6e00ff4b2875ee24674/aspects/nvim/files/.config/nvim/lua/wincent/lsp.lua#L203-L250
			local config_directory = vim.fn.stdpath 'config'

			--- @param a string A path
			--- @param b string A possible prefix matching or included in that path
			--- @return boolean Does path `a` include `b` as a prefix?
			local function has_prefix(a, b)
				return string.sub(a .. '/', 1, #(b .. '/')) == (b .. '/')
			end

			-- `nvim_get_runtime_file()` will return:
			--
			-- - The top-level config path (ie. "~/.config/nvim")
			-- - Special folders inside the top-level, like "~/.config/nvim/after"
			-- - Plug-in paths like "~/.config/nvim/pack/bundle/opt/command-t"
			-- - System paths like "/opt/homebrew/Cellar/neovim/0.11.2/share/nvim/runtime"
			--
			-- If we include paths that are nested inside other paths
			-- lua-language-server will actually read some files more than once, and
			-- produce spurious `duplicate-doc-field` diagnostics.
			--
			-- Additionally, passing our own config file or plug-in files into
			-- "workspace.library" is likely a misuse of the setting; the docs state
			-- it is for "library implementation code and definition files" (the later
			-- should generally be tagged with `@meta`, and not include executable Lua
			-- code).
			--
			-- So, filter out the main config path and anything that's under it. This
			-- is what definitively resolves the `duplicate-doc-field` diagnostics.
			--
			-- See:
			-- - https://github.com/neovim/nvim-lspconfig/issues/3189
			-- - https://github.com/LuaLS/lua-language-server/issues/2061
			-- - https://luals.github.io/wiki/settings/#workspacelibrary
			-- - https://luals.github.io/wiki/definition-files/
			local function get_library_directories(options)
				local filter = options and options.filter or false
				local runtime_directories = vim.api.nvim_get_runtime_file('', true)
				if filter then
					return vim.tbl_filter(function(path)
						-- Keep directory unless it coincides with the config directory (or
						-- is inside it).
						return not has_prefix(path, config_directory)
					end, runtime_directories)
				else
					return runtime_directories
				end
			end

			vim.lsp.config('lua_ls', {
				root_markers = {
					{
						'.luarc.json',
						'.luarc.jsonc',
						'.luacheckrc',
						'.stylua.toml',
						'stylua.toml',
					},
					'.git',
				},
				settings = {
					Lua = {
						telemetry = { enable = false },
						workspace = {
							ignoreDir = {
								'.direnv',
							},
						},
					},
				},
				on_init = function(client)
					if client.workspace_folders then
						-- Found a root marker.
						local path = client.workspace_folders[1].name
						if
							vim.uv.fs_stat(path .. '/.luarc.json')
							or vim.uv.fs_stat(path .. '/.luarc.jsonc')
						then
							return
						end

						-- Is the workspace somewhere under "~/.nvim/config" or any runtime
						-- directory?
						local real_workspace_path = vim.uv.fs_realpath(path)
						local library_directories = get_library_directories()
						for _, library_directory in ipairs(library_directories) do
							local real_library_directory_path =
								vim.uv.fs_realpath(library_directory)
							if
								real_workspace_path
								and real_library_directory_path
								and has_prefix(real_workspace_path, real_library_directory_path)
							then
								-- Provide defaults for my common case (working on Neovim Lua).
								client.config.settings.Lua =
									vim.tbl_deep_extend('force', client.config.settings.Lua, {
										diagnostics = {
											enable = true,
											globals = { 'vim' },
										},
										filetypes = { 'lua' },
										runtime = {
											path = {
												-- Load modules the same was as Neovim does (see `:help lua-module-load`).
												'lua/?.lua',
												'lua/?/init.lua',
											},
											version = 'LuaJIT',
										},
										workspace = {
											-- Make the server aware of Neovim runtime files.
											library = get_library_directories { filter = true },
											-- Stop "Do you need to configure your work environment as
											-- `luassert`?" spam.
											checkThirdParty = false,
										},
									})

								client:notify(
									vim.lsp.protocol.Methods.workspace_didChangeConfiguration,
									{ settings = client.config.settings }
								)
							end
						end
					end
				end,
			})

			vim.lsp.config('rust_analyzer', {
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
			})

			vim.lsp.config('gopls', {
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
					on_dir(
						vim.fs.root(0, { 'go.mod', '.git', vim.api.nvim_buf_get_name(0) })
					)
				end,
			})

			-- Use the same settings for JS and TS.
			local lang_settings = {
				suggest = { completeFunctionCalls = true },
				inlayHints = {
					functionLikeReturnTypes = { enabled = true },
					parameterNames = { enabled = 'literals' },
					variableTypes = { enabled = true },
				},
			}

			local tsgo = vim.fn.executable 'tsgo' ~= 0

			vim.lsp.config('tsgo', {
				cmd = { 'tsgo', 'lsp', '--stdio' },
				workspace_required = true,
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
			})

			vim.lsp.config('vtsls', {
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
			})

			vim.lsp.config('denols', {
				root_dir = function(_bufnr, on_dir)
					on_dir(vim.fs.root(0, { 'deno.json', 'deno.jsonc' }))
				end,
			})

			vim.lsp.config('oxlint', {
				cmd = { utils.get_lsp_bin 'oxc_language_server' },
			})

			vim.lsp.config('nixd', {
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
			})

			vim.lsp.config('ast_grep', {
				cmd = { utils.get_lsp_bin 'ast-grep', 'lsp' },
			})

			vim.lsp.config('taplo', {
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
			})

			vim.lsp.config('jsonls', {
				settings = {
					json = {
						validate = { enable = true },
						format = { enable = true },
						schemas = require('schemastore').json.schemas {},
					},
				},
			})

			vim.lsp.config('yamlls', {
				settings = {
					yaml = {
						schemaStore = {
							-- You must disable built-in schemaStore support if you want to use
							-- this plugin and its advanced options like `ignore`.
							enable = false,
							-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
							url = '',
						},
						schemas = require('schemastore').yaml.schemas {},
					},
				},
			})

			vim.lsp.config('typos_lsp', {
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
			})

			local servers = {
				{ 'cssls', 'vscode-css-language-server' },
				{ 'stylelint_lsp', 'stylelint-lsp' },
				{ 'html', 'vscode-html-language-server' },
				{ 'eslint', 'vscode-eslint-language-server' },
				{ 'oxlint', utils.get_lsp_bin 'oxc_language_server' },
				{ 'tsgo', tsgo },
				{ 'vtsls', not tsgo },
				{ 'denols', 'deno' },
				{ 'tailwindcss', 'tailwindcss-language-server' },

				{ 'dockerls', 'docker-langserver' },
				{ 'docker_compose_language_service' },

				{ 'pyright', 'pyright-langserver' },
				{ 'ruff' },

				{ 'bashls', 'bash-language-server' },
				{ 'lua_ls', 'lua-language-server' },
				{ 'rust_analyzer' },
				{ 'gopls' },
				{ 'nixd' },
				{ 'ast_grep', utils.get_lsp_bin 'ast-grep' },
				{ 'taplo' },
				{ 'jsonls', 'vscode-json-language-server' },
				{ 'yamlls', 'yaml-language-server' },
				{ 'typos_lsp', 'typos-lsp' },
				{ 'mutt_ls', 'mutt-language-server' },
			}

			for _, value in ipairs(servers) do
				local lsp, enableOrExecutable = value[1], value[2]
				local enable = true

				if type(enableOrExecutable) == 'boolean' then
					enable = enableOrExecutable
				end

				if type(enableOrExecutable) == 'string' then
					enable = vim.fn.executable(enableOrExecutable) ~= 0
				end

				if type(enableOrExecutable) == 'nil' then
					enable = vim.fn.executable(lsp) ~= 0
				end

				-- only enable the ones that have their executable available
				vim.lsp.enable(lsp, enable)
			end

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
								require('fzf-lua').lsp_code_actions {
									winopts = {
										preview = { hidden = 'hidden' },
										relative = 'cursor',
										row = 1.01,
										col = 0,
										height = 0.2,
										width = 0.4,
									},
								}
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
						{
							{ 'n' },
							']e',
							function()
								vim.diagnostic.jump {
									count = 1,
									severity = vim.diagnostic.severity.ERROR,
								}
							end,
							{ desc = 'Next [E]rror' },
						},
						{
							{ 'n' },
							'[e',
							function()
								vim.diagnostic.jump {
									count = -1,
									severity = vim.diagnostic.severity.ERROR,
								}
							end,
							{ desc = 'Previous [E]rror' },
						},
					} do
						local extra_opts = table.remove(item, 4)
						local merged_opts = vim.tbl_extend('force', map_opts, extra_opts)

						table.insert(item, 4, merged_opts)

						local modes, lhs, rhs, opt = item[1], item[2], item[3], item[4]

						vim.keymap.set(modes, lhs, rhs, opt)
					end

					-- ---------------
					-- GENERAL
					-- ---------------
					client.flags.allow_incremental_sync = true

					if
						client:supports_method(
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

						vim.api.nvim_create_autocmd('LspDetach', {
							group = vim.api.nvim_create_augroup(
								'__LSP_HIGHLIGHTS_DETACH__',
								{ clear = true }
							),
							callback = function(ev)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds {
									group = group,
									buffer = ev.buf,
								}
							end,
						})
					end

					if
						client:supports_method(
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
						client:supports_method(
							vim.lsp.protocol.Methods.textDocument_foldingRange
						)
					then
						local win = vim.api.nvim_get_current_win()
						vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
					end

					if
						client:supports_method(
							vim.lsp.protocol.Methods.textDocument_completion
						) and not package.loaded['blink.cmp']
					then
						vim.lsp.completion.enable(
							true,
							client.id,
							bufnr,
							{ autotrigger = true }
						)
					end

					if
						client.name == 'gopls'
						and not client.server_capabilities.semanticTokensProvider
					then
						local semantic =
							client.config.capabilities.textDocument.semanticTokens

						assert(semantic, "doesn't support semantic tokens")

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

			au.autocmd {
				event = 'LspNotify',
				desc = 'Auto fold imports',
				callback = function(args)
					if args.data.method == 'textDocument/didOpen' then
						vim.lsp.foldclose('imports', vim.fn.bufwinid(args.buf))
					end
				end,
			}
		end,
	},
}
