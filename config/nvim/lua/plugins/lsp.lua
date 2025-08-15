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

					nls.builtins.code_actions.gitrebase,
					nls.builtins.code_actions.statix,
					nls.builtins.hover.dictionary,
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

			local tsgo = vim.fn.executable 'tsgo' ~= 0

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
							'K',
							function()
								vim.lsp.buf.hover {
									width = 50,
									max_width = 300,
								}
							end,
							{ desc = 'Hover' },
						},
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
							{ desc = 'Open diagnostic [Q]uickfix list' },
						},
						{
							{ 'n' },
							'<leader>k',
							function()
								if vim.diagnostic.config().virtual_lines then
									vim.diagnostic.config { virtual_lines = false }
								else
									vim.diagnostic.config { virtual_lines = true }
								end
							end,
							{ desc = 'Toggle virtual lines' },
						},
						{
							{ 'n' },
							'<leader>ld',
							function()
								vim.diagnostic.open_float(nil)
							end,
							{ desc = 'Show diagnostic [E]rror messages' },
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
