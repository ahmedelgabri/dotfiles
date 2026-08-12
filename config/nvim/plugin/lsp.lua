local pack = require '_.pack'
local utils = require '_.utils'

pack.add {
	{ src = 'https://github.com/b0o/SchemaStore.nvim' },
	{
		src = 'https://github.com/SmiteshP/nvim-navic',
		event = { 'LspAttach' },
		config = function(ev)
			require('nvim-navic').setup {
				click = true,
				highlight = true,
				lsp = {
					auto_attach = true,
					preference = { 'markdown_oxide' },
				},
			}

			vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"

			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if
				client
				and client.server_capabilities
				and client.server_capabilities.documentSymbolProvider
			then
				pcall(require('nvim-navic').attach, client, ev.buf)
			end
		end,
	},
	{
		src = 'https://github.com/neovim/nvim-lspconfig',
		event = { 'UIEnter' },
		config = function()
			local lsp_markdown = require '_.lsp_markdown'
			local open_floating_preview = vim.lsp.util.open_floating_preview

			vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
				if not opts or opts.focus_id ~= 'textDocument/hover' then
					return open_floating_preview(contents, syntax, opts)
				end

				local reflowed, links = lsp_markdown.reflow(
					table.concat(contents, '\n'),
					{ remove_separators = true }
				)
				contents = vim.split(reflowed, '\n', { plain = true })
				opts = vim.tbl_extend('force', {}, opts, {
					border = utils.get_border(),
					max_height = 20,
					max_width = 80,
				})

				local source_win = vim.api.nvim_get_current_win()
				if vim.api.nvim_win_get_config(source_win).relative ~= '' then
					source_win = nil
				end

				local bufnr, win = open_floating_preview(contents, syntax, opts)
				if package.loaded['render-markdown'] then
					vim.api.nvim_buf_call(bufnr, function()
						require('render-markdown').buf_disable()
					end)
					local namespace =
						vim.api.nvim_get_namespaces()['render-markdown.nvim']
					if namespace then
						vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
					end
				end

				lsp_markdown.configure_hover(bufnr, win, links, source_win)
				return bufnr, win
			end

			-- for debugging
			-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
			-- :lua print(vim.lsp.log.get_filename())
			-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

			-- require('vim.lsp.log').set_level 'debug'
			-- require('vim.lsp.log').set_format_func(vim.inspect)
			local au = require '_.utils.au'

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

			vim.lsp.config('docker_language_server', {
				init_options = {
					telemetry = 'off',
					-- both this server and dockerls lint Dockerfiles, so drop
					-- the duplicated diagnostics
					dockerfileExperimental = {
						removeOverlappingIssues = true,
					},
				},
			})

			local servers = {
				{ 'cssls', 'vscode-css-language-server' },
				{ 'stylelint_lsp', 'stylelint-lsp' },
				{ 'html', 'vscode-html-language-server' },
				{ 'eslint', 'vscode-eslint-language-server' },
				{ 'oxlint', utils.get_lsp_bin 'oxlint' },
				{ 'oxfmt', utils.get_lsp_bin 'oxfmt' },
				{ 'tsgo', utils.get_lsp_bin 'tsgo' ~= nil },
				{ 'vtsls', utils.get_lsp_bin 'tsgo' == nil },
				{ 'denols', 'deno' },
				{ 'biome', utils.get_lsp_bin 'biome' },
				{ 'tailwindcss', 'tailwindcss-language-server' },

				{ 'dockerls', 'docker-langserver' },
				{ 'docker_compose_language_service', 'docker-compose-langserver' },
				{ 'docker_language_server', 'docker-language-server' },

				{ 'ty' },
				{ 'ruff' },

				{ 'bashls', 'bash-language-server' },
				{ 'lua_ls', 'lua-language-server' },
				{ 'rust_analyzer', 'rust-analyzer' },
				{ 'gopls' },
				{ 'nixd' },
				{ 'ast_grep', utils.get_lsp_bin 'ast-grep' },
				{ 'taplo' },
				{ 'jsonls', 'vscode-json-language-server' },
				{ 'yamlls', 'yaml-language-server' },
				{ 'typos_lsp', 'typos-lsp' },
				{ 'mutt_ls', 'mutt-language-server' },
				{ 'markdown_oxide', 'markdown-oxide' },
				{ 'tinymist' }, -- typst LSP
				{ 'kotlin_lsp', 'kotlin-lsp' },
				{ 'astro', 'astro-ls' },
			}

			for _, value in ipairs(servers) do
				local lsp, enableOrExecutable = value[1], value[2]
				local enable = true

				if type(enableOrExecutable) == 'boolean' then
					enable = enableOrExecutable
				end

				if type(enableOrExecutable) == 'string' then
					enable = vim.fn.executable(enableOrExecutable) == 1
				end

				if type(enableOrExecutable) == 'nil' then
					enable = vim.fn.executable(lsp) == 1
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
							vim.lsp.buf.hover,
							{ desc = 'Hover' },
						},
						{
							{ 'n' },
							'<C-]>',
							function()
								vim.lsp.buf.definition()
							end,
							{ desc = 'Go to Definition' },
						},
						{
							{ 'n' },
							'<leader>a',
							function()
								-- vim.lsp.buf.code_action()
								vim.cmd.packadd 'tiny-code-action.nvim'

								require('tiny-code-action').code_action()
							end,
							{ desc = 'Code [A]ctions' },
						},
						{
							{ 'n' },
							'<leader>f',
							function()
								vim.lsp.buf.references()
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
								vim.lsp.buf.declaration()
							end,
							{ desc = 'Go to [D]eclaration' },
						},
						{
							{ 'n' },
							'<leader>i',
							function()
								vim.lsp.buf.implementation()
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
								vim.cmd 'normal! zz'
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
								vim.cmd 'normal! zz'
							end,
							{ desc = 'Previous [E]rror' },
						},
					} do
						local extra_opts = table.remove(item, 4)
						local merged_opts = vim.tbl_extend(
							'force',
							{ silent = true, buf = bufnr },
							extra_opts
						)

						table.insert(item, 4, merged_opts)

						local modes, lhs, rhs, opt = item[1], item[2], item[3], item[4]

						vim.keymap.set(modes, lhs, rhs, opt)
					end

					-- ---------------
					-- GENERAL
					-- ---------------
					client.flags.allow_incremental_sync = true

					if client:supports_method 'textDocument/documentHighlight' then
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

					if client:supports_method 'textDocument/codeLens' then
						vim.lsp.codelens.enable(true, {
							bufnr = bufnr,
						})
					end

					if client:supports_method 'textDocument/linkedEditingRange' then
						vim.lsp.linked_editing_range.enable(true, {
							client_id = client.id,
						})
					end

					if client:supports_method 'textDocument/foldingRange' then
						local win = vim.api.nvim_get_current_win()
						vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
					end

					-- blink.cmp replaces built-in completion, so
					-- vim.lsp.completion is intentionally never enabled

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

			local function lsp_status()
				local current_bufnr = vim.api.nvim_get_current_buf()
				local clients = vim.lsp.get_clients { bufnr = current_bufnr }

				if #clients == 0 then
					print '󰅚 No LSP clients attached'
					return
				end

				print('󰒋 LSP Status for buffer ' .. current_bufnr .. ':')
				print '─────────────────────────────────'

				for i, client in ipairs(clients) do
					print(
						string.format(
							'󰌘 Client %d: %s (ID: %d)',
							i,
							client.name,
							client.id
						)
					)
					print('  Root: ' .. (client.config.root_dir or 'N/A'))
					print(
						'  Filetypes: ' .. table.concat(client.config.filetypes or {}, ', ')
					)

					local caps = client.server_capabilities

					if caps == nil then
						return
					end

					local features = {}
					if caps.completionProvider then
						table.insert(features, 'completion')
					end
					if caps.hoverProvider then
						table.insert(features, 'hover')
					end
					if caps.definitionProvider then
						table.insert(features, 'definition')
					end
					if caps.referencesProvider then
						table.insert(features, 'references')
					end
					if caps.renameProvider then
						table.insert(features, 'rename')
					end
					if caps.codeActionProvider then
						table.insert(features, 'code_action')
					end
					if caps.documentFormattingProvider then
						table.insert(features, 'formatting')
					end

					print('  Features: ' .. table.concat(features, ', '))
					print ''
				end
			end

			local function check_lsp_capabilities()
				local current_bufnr = vim.api.nvim_get_current_buf()
				local clients = vim.lsp.get_clients { bufnr = current_bufnr }

				if #clients == 0 then
					print 'No LSP clients attached'
					return
				end

				for _, client in ipairs(clients) do
					print('Capabilities for ' .. client.name .. ':')
					local caps = client.server_capabilities

					if caps == nil then
						return
					end

					local capability_list = {
						{ 'Completion', caps.completionProvider },
						{ 'Hover', caps.hoverProvider },
						{ 'Signature Help', caps.signatureHelpProvider },
						{ 'Go to Definition', caps.definitionProvider },
						{ 'Go to Declaration', caps.declarationProvider },
						{ 'Go to Implementation', caps.implementationProvider },
						{ 'Go to Type Definition', caps.typeDefinitionProvider },
						{ 'Find References', caps.referencesProvider },
						{ 'Document Highlight', caps.documentHighlightProvider },
						{ 'Document Symbol', caps.documentSymbolProvider },
						{ 'Workspace Symbol', caps.workspaceSymbolProvider },
						{ 'Code Action', caps.codeActionProvider },
						{ 'Code Lens', caps.codeLensProvider },
						{ 'Document Formatting', caps.documentFormattingProvider },
						{
							'Document Range Formatting',
							caps.documentRangeFormattingProvider,
						},
						{ 'Rename', caps.renameProvider },
						{ 'Folding Range', caps.foldingRangeProvider },
						{ 'Selection Range', caps.selectionRangeProvider },
					}

					for _, cap in ipairs(capability_list) do
						local status = cap[2] and '✓' or '✗'
						print(string.format('  %s %s', status, cap[1]))
					end
					print ''
				end
			end

			vim.api.nvim_create_user_command('LspStatus', lsp_status, {
				desc = 'Show detailed LSP status',
			})
			vim.api.nvim_create_user_command(
				'LspCapabilities',
				check_lsp_capabilities,
				{
					desc = 'Show LSP capabilities',
				}
			)
			vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', {
				desc = 'Show LSP Info',
			})
			vim.api.nvim_create_user_command('LspLog', function(_)
				local state_path = vim.fn.stdpath 'state'
				local log_path = vim.fs.joinpath(state_path, 'lsp.log')

				vim.cmd(string.format('edit %s', log_path))
			end, {
				desc = 'Show LSP log',
			})
		end,
	},
	{
		src = 'https://github.com/rachartier/tiny-code-action.nvim',
		event = { 'LspAttach' },
	},
}
