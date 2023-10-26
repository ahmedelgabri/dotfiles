local function setup_null(on_attach)
	local ok, nls = pcall(require, 'null-ls')

	if not ok then
		return
	end

	nls.setup {
		debug = false,
		debounce = 150,
		on_attach = on_attach,
		sources = {
			-- nixlinter,
			nls.builtins.diagnostics.shellcheck.with {
				filetypes = { 'sh', 'bash' },
			},
			nls.builtins.diagnostics.ruff,
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
					return cwd:find '.github/workflows'
				end,
			},
		},
	}
end

return {
	'https://github.com/neovim/nvim-lspconfig',
	event = { 'BufReadPre' },
	dependencies = {
		{
			'https://github.com/j-hui/fidget.nvim',
			tag = 'legacy',
			opts = {
				window = {
					relative = 'editor', -- where to anchor the window, either `"win"` or `"editor"`
					blend = 0, -- `&winblend` for the window
				},
				text = {
					spinner = 'dots',
				},
			},
		},
		{
			'https://github.com/jose-elias-alvarez/null-ls.nvim',
			dependencies = {
				'https://github.com/nvim-lua/plenary.nvim',
			},
		},
		{
			'https://github.com/folke/trouble.nvim',
			cmd = { 'Trouble' },
			opts = { icons = false },
		},
		{
			'https://github.com/folke/neodev.nvim',
			opts = {},
		},
		{ 'https://github.com/mickael-menu/zk-nvim' },
		{
			'https://github.com/b0o/SchemaStore.nvim',
		},
		{
			'https://github.com/lewis6991/hover.nvim',
			config = function()
				require('hover').setup {
					init = function()
						require 'hover.providers.lsp'
						require 'hover.providers.gh'
						require '_.hover.github_user'
						require 'hover.providers.jira'
						require 'hover.providers.man'
						require 'hover.providers.dictionary'
					end,
				}

				-- Setup keymaps
				vim.keymap.set(
					'n',
					'K',
					require('hover').hover,
					{ desc = 'Open hover popup' }
				)
				vim.keymap.set(
					'n',
					'gK',
					require('hover').hover_select,
					{ desc = 'Select hover popup source' }
				)
			end,
		},
	},
	config = function()
		-- for debugging
		-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
		-- :lua print(vim.lsp.get_log_path())
		-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

		-- require('vim.lsp.log').set_level 'debug'
		-- require('vim.lsp.log').set_format_func(vim.inspect)

		local has_lsp, nvim_lsp = pcall(require, 'lspconfig')
		local utils = require '_.utils'
		local au = require '_.utils.au'
		local hl = require '_.utils.highlight'
		local map_opts = { buffer = true, silent = true }

		if not has_lsp then
			utils.notify 'LSP config failed to setup'
			return
		end

		local signs = { 'Error', 'Warn', 'Hint', 'Info' }

		for _, type in pairs(signs) do
			vim.fn.sign_define('DiagnosticSign' .. type, {
				text = utils.get_icon(string.lower(type)),
				texthl = 'DiagnosticSign' .. type,
				linehl = '',
				numhl = '',
			})
		end

		local function getBorder(highlight)
			return {
				{ '╭', highlight or 'FloatBorder' },
				{ '─', highlight or 'FloatBorder' },
				{ '╮', highlight or 'FloatBorder' },
				{ '│', highlight or 'FloatBorder' },
				{ '╯', highlight or 'FloatBorder' },
				{ '─', highlight or 'FloatBorder' },
				{ '╰', highlight or 'FloatBorder' },
				{ '│', highlight or 'FloatBorder' },
			}
		end

		-- globally override borders
		-- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#borders
		local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
		function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
			opts = opts or {}
			opts.border = opts.border or getBorder()
			return orig_util_open_floating_preview(contents, syntax, opts, ...)
		end

		-- wrap open_float to inspect diagnostics and use the severity color for border
		-- https://neovim.discourse.group/t/lsp-diagnostics-how-and-where-to-retrieve-severity-level-to-customise-border-color/1679
		vim.diagnostic.open_float = (function(orig)
			return function(bufnr, options)
				local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
				local opts = options or {}
				-- A more robust solution would check the "scope" value in `opts` to
				-- determine where to get diagnostics from, but if you're only using
				-- this for your own purposes you can make it as simple as you like
				local diagnostics = vim.diagnostic.get(opts.bufnr or 0, { lnum = lnum })
				local max_severity = vim.diagnostic.severity.HINT
				for _, d in ipairs(diagnostics) do
					-- Equality is "less than" based on how the severities are encoded
					if d.severity < max_severity then
						max_severity = d.severity
					end
				end
				local border_color = ({
					[vim.diagnostic.severity.HINT] = 'DiagnosticHint',
					[vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
					[vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
					[vim.diagnostic.severity.ERROR] = 'DiagnosticError',
				})[max_severity]
				opts.border = getBorder(border_color)
				orig(bufnr, opts)
			end
		end)(vim.diagnostic.open_float)

		vim.diagnostic.config {
			virtual_text = false,
			-- virtual_text = {
			--   source = 'always',
			--   spacing = 4,
			--   prefix = '■', -- Could be '●', '▎', 'x'
			-- },
			float = {
				source = 'always',
				focusable = false,
				style = 'minimal',
				border = getBorder(),
				-- header = '',
				-- prefix = '',
			},
			underline = true,
			signs = true,
			update_in_insert = false,
			severity_sort = true,
		}

		local mappings = {
			{
				{ 'n' },
				'<leader>a',
				'<cmd>lua vim.lsp.buf.code_action()<CR>',
				{ desc = 'Code [A]ctions' },
			},
			{
				{ 'n' },
				'<leader>f',
				'<cmd>lua vim.lsp.buf.references()<CR>',
				{ desc = 'Show Re[f]erences' },
			},
			{
				{ 'n' },
				'<leader>r',
				'<cmd>lua vim.lsp.buf.rename()<CR>',
				{ desc = '[R]ename Symbol' },
			},
			-- { { 'n' }, 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', {desc = "Open Hover popup"} },
			{
				{ 'n' },
				'<leader>ld',
				'<cmd>lua vim.diagnostic.open_float(nil, { focusable = false,  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" }, source = "always" })<CR>',
				{ desc = '[L]ist [D]iagnostics' },
			},
			{
				{ 'n' },
				'[d',
				'<cmd>lua vim.diagnostic.goto_next()<cr>',
				{ desc = 'Next diagnostic' },
			},
			{
				{ 'n' },
				']d',
				'<cmd>lua vim.diagnostic.goto_prev()<CR>',
				{ desc = 'Prev diagnostic' },
			},
			{
				{ 'n' },
				'<C-]>',
				'<cmd>lua vim.lsp.buf.definition()<CR>',
				{ desc = 'Go To Definition' },
			},
			{
				{ 'n' },
				'<leader>D',
				'<cmd>lua vim.lsp.buf.declaration()<CR>',
				{ desc = 'Go to [D]eclaration' },
			},
			{
				{ 'n' },
				'<leader>i',
				'<cmd>lua vim.lsp.buf.implementation()<CR>',
				{ desc = 'Go to [I]mplementation' },
			},
		}

		local handlers = {
			['textDocument/hover'] = vim.lsp.with(
				vim.lsp.handlers.hover,
				{ focusable = false, silent = true }
			),
			['textDocument/signatureHelp'] = vim.lsp.with(
				vim.lsp.handlers.hover,
				{ focusable = false, silent = true }
			),
		}

		local on_attach = function(client, bufnr)
			local bufname = vim.api.nvim_buf_get_name(0)

			-- Don't run bash-lsp on .env files
			-- Has to be in-sync with null-ls config for shellcheck
			if
				client.name == 'bashls'
				and bufname:match '%.env' ~= nil
				and bufname:match '%.env.*' ~= nil
			then
				vim.cmd.LspStop()
				return
			end

			-- ---------------
			-- GENERAL
			-- ---------------
			client.config.flags.allow_incremental_sync = true

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
			if client.server_capabilities.documentHighlightProvider then
				hl.group('LspReferenceRead', {
					link = 'SpecialKey',
				})
				hl.group('LspReferenceText', {
					link = 'SpecialKey',
				})
				hl.group('LspReferenceWrite', {
					link = 'SpecialKey',
				})

				au.augroup('__LSP_HIGHLIGHTS__', {
					{
						event = 'CursorHold',
						callback = function()
							vim.lsp.buf.document_highlight()
						end,
						buffer = 0,
					},
					{
						event = 'CursorMoved',
						callback = function()
							vim.lsp.buf.clear_references()
						end,
						buffer = 0,
					},
				})
			end

			if client.server_capabilities.codeLensProvider then
				au.augroup('__LSP_CODELENS__', {
					{
						event = { 'CursorHold', 'BufEnter', 'InsertLeave' },
						callback = function()
							vim.lsp.codelens.refresh()
						end,
						buffer = 0,
					},
				})
			end
		end

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
						-- tailwindcss lang server waits for this repsonse before providing hover
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
							setType = true,
							paramName = 'Disable',
						},
						doc = {
							privateName = { '^_' },
						},
						format = { enable = false },
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
							checkThirdParty = false,
							maxPreload = 1000,
							preloadFileSize = 1000,
							library = {
								['/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/'] = true,
							},
						},
						completion = { keywordSnippet = 'Replace', callSnippet = 'Replace' },
						telemetry = { enable = false },
					},
				},
			},
			rust_analyzer = {},
			gopls = {
				cmd = { 'gopls', 'serve' },
				root_dir = function(fname)
					return nvim_lsp.util.root_pattern('go.mod', '.git')(fname)
						or nvim_lsp.util.path.dirname(fname)
				end,
			},
			tsserver = {
				root_dir = function(fname)
					return not nvim_lsp.util.root_pattern(
						'.flowconfig',
						'deno.json',
						'deno.jsonc'
					)(fname) and (nvim_lsp.util.root_pattern 'tsconfig.json'(fname) or nvim_lsp.util.root_pattern(
						'package.json',
						'jsconfig.json',
						'.git'
					)(fname) or nvim_lsp.util.path.dirname(fname))
				end,
			},
			denols = {
				root_dir = nvim_lsp.util.root_pattern('deno.json', 'deno.jsonc'),
			},
			nil_ls = {},
			jsonls = {
				filetypes = { 'json', 'jsonc' },
				settings = {
					json = {
						schemas = require('schemastore').json.schemas {},
						validate = { enable = true },
					},
				},
			},
			yamlls = {
				settings = {
					yaml = {
						-- Schemas https://www.schemastore.org
						schemas = {
							['http://json.schemastore.org/gitlab-ci.json'] = {
								'.gitlab-ci.yml',
							},
							['https://json.schemastore.org/bamboo-spec.json'] = {
								'bamboo-specs/*.{yml,yaml}',
							},
							['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = {
								'docker-compose*.{yml,yaml}',
							},
							['http://json.schemastore.org/github-workflow.json'] = '.github/workflows/*.{yml,yaml}',
							['http://json.schemastore.org/github-action.json'] = '.github/action.{yml,yaml}',
							['http://json.schemastore.org/prettierrc.json'] = '.prettierrc.{yml,yaml}',
							['http://json.schemastore.org/stylelintrc.json'] = '.stylelintrc.{yml,yaml}',
							['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}',
						},
					},
				},
			},
		}

		local capabilities = vim.lsp.protocol.make_client_capabilities()

		if pcall(require, 'cmp_nvim_lsp') then
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
		else
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			capabilities.textDocument.completion.completionItem.resolveSupport = {
				properties = {
					'documentation',
					'detail',
					'additionalTextEdits',
				},
			}
		end

		local shared = {
			on_attach = on_attach,
			capabilities = capabilities,
			handlers = handlers,
			flags = {
				debounce_text_changes = 150,
			},
		}

		for server, config in pairs(servers) do
			local server_disabled = (config.disabled ~= nil and config.disabled)
				or false

			if not server_disabled then
				nvim_lsp[server].setup(vim.tbl_deep_extend('force', shared, config))
			end
		end

		setup_null(on_attach)

		pcall(function()
			require('zk').setup {
				picker = 'fzf',
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
		end)
	end,
}
