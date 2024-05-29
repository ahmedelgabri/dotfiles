return {
	{
		'https://github.com/stevearc/conform.nvim',
		event = {
			'LspAttach',
			'BufWritePre',
		},
		cmd = { 'ConformInfo' },
		config = function()
			local slow_format_filetypes = {}

			local function disable_autoformat(bufnr)
				-- Disable with a global or buffer-local variable
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return true
				end

				-- Disable autoformat for files in a certain path
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match '/node_modules/' then
					return true
				end
			end

			require('conform').setup {
				formatters = {
					stylua = {
						prepend_args = function(_, ctx)
							return {
								'--sort-requires',
								'--line-endings',
								'Unix',
								'--quote-style',
								'AutoPreferSingle',
								'--call-parentheses',
								'None',
								'--indent-width',
								vim.bo[ctx.buf].tabstop,
								'--column-width',
								vim.bo[ctx.buf].textwidth,
							}
						end,
					},
					-- Look into dprint as my default formatter instead
					prettier = {
						cwd = function()
							return vim.uv.cwd()
						end,
						prepend_args = function(_, ctx)
							return {
								'--config-precedence',
								'prefer-file',
								'--use-tabs',
								'--single-quote',
								'--no-bracket-spacing',
								'--prose-wrap',
								'always',
								'--arrow-parens',
								'always',
								'--trailing-comma',
								'all',
								'--no-semi',
								'--end-of-line',
								'lf',
								'--print-width',
								vim.bo[ctx.buf].textwidth <= 80 and 80
									or vim.bo[ctx.buf].textwidth,
							}
						end,
					},

					statix = {
						command = 'statix',
						args = { 'fix', '--stdin' },
						stdin = true,
					},
				},
				formatters_by_ft = {
					['*'] = {
						'trim_whitespace',
						'trim_newlines',
					},
					javascript = { { 'deno_fmt', 'prettier' } },
					typescript = { { 'deno_fmt', 'prettier' } },
					javascriptreact = { { 'deno_fmt', 'prettier' } },
					['javascriptreact.jest'] = { { 'deno_fmt', 'prettier' } },
					typescriptreact = { { 'deno_fmt', 'prettier' } },
					['typescriptreact.jest'] = { { 'deno_fmt', 'prettier' } },
					['javascript.jsx'] = { { 'deno_fmt', 'prettier' } },
					['typescript.tsx'] = { { 'deno_fmt', 'prettier' } },
					['javascript.jest'] = { { 'deno_fmt', 'prettier' } },
					['typescript.jest'] = { { 'deno_fmt', 'prettier' } },
					json = { { 'deno_fmt', 'prettier' } },
					jsonc = { { 'deno_fmt', 'prettier' } },
					markdown = { { 'deno_fmt', 'prettier' }, 'injected' },
					['markdown.mdx'] = { 'prettier', 'injected' },
					mdx = { 'prettier', 'injected' },
					css = { 'prettier' },
					vue = { 'prettier' },
					scss = { 'prettier' },
					less = { 'prettier' },
					yaml = { 'prettier', 'injected' },
					graphql = { 'prettier' },
					html = { 'prettier', 'injected' },
					lua = { 'stylua' },
					python = { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
					sh = { 'shfmt' },
					bash = { 'shfmt' },
					rust = { 'rustfmt' },
					go = {
						-- this will run gofmt too
						'goimports',
					},
					nix = { 'nixpkgs_fmt', 'statix' },
					toml = { 'taplo' },
				},
				format_on_save = function(bufnr)
					if disable_autoformat(bufnr) then
						---@diagnostic disable-next-line: missing-return-value
						return
					end

					-- Automatically run slow formatters async
					if slow_format_filetypes[vim.bo[bufnr].filetype] then
						---@diagnostic disable-next-line: missing-return-value
						return
					end

					local function on_format(err)
						if err and err:match 'timeout$' then
							slow_format_filetypes[vim.bo[bufnr].filetype] = true
						end
					end

					return {
						lsp_fallback = true,
					},
						---@diagnostic disable-next-line: redundant-return-value
						on_format
				end,

				format_after_save = function(bufnr)
					if disable_autoformat(bufnr) then
						---@diagnostic disable-next-line: missing-return-value
						return
					end

					if not slow_format_filetypes[vim.bo[bufnr].filetype] then
						---@diagnostic disable-next-line: missing-return-value
						return
					end
					return { lsp_fallback = true }
				end,
			}
		end,
		init = function()
			-- Use conform for gq.
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

			-- Define a command to run async formatting
			vim.api.nvim_create_user_command('Format', function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line =
						vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = {
						start = { args.line1, 0 },
						['end'] = { args.line2, end_line:len() },
					}
				end
				require('conform').format {
					async = true,
					lsp_fallback = true,
					range = range,
				}
			end, { range = true })
		end,
	},
}
