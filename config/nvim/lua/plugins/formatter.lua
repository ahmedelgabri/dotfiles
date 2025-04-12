---@param bufnr integer
---@param ... string
---@return string
local function first(bufnr, ...)
	local conform = require 'conform'
	for i = 1, select('#', ...) do
		local formatter = select(i, ...)
		if conform.get_formatter_info(formatter, bufnr).available then
			return formatter
		end
	end
	return select(1, ...)
end

local js_formats = {}
for _, ft in ipairs {
	'javascript',
	'javascript.jsx',
	'javascriptreact',
	'typescript',
	'typescript.tsx',
	'typescriptreact',
} do
	js_formats[ft] = {
		'deno_fmt',
		'prettier',
		stop_after_first = true,
	}
end

return {
	{
		'https://github.com/stevearc/conform.nvim',
		event = { 'BufWritePre' },
		cmd = { 'ConformInfo' },
		---@module "conform"
		---@type conform.setupOpts
		opts = {
			formatters = {
				injected = {
					options = {
						ignore_errors = true,
					},
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
			formatters_by_ft = vim.tbl_extend('force', {
				['*'] = { 'trim_whitespace', 'trim_newlines' },
				json = {
					'deno_fmt',
					'prettier',
					'jq',
					stop_after_first = true,
				},
				jsonc = {
					'deno_fmt',
					'prettier',
					stop_after_first = true,
				},
				markdown = function(bufnr)
					return { first(bufnr, 'deno_fmt', 'prettier'), 'injected' }
				end,
				['markdown.mdx'] = { 'prettier', 'injected' },
				mdx = { 'prettier', 'injected' },
				html = { 'prettier', 'injected' },
				yaml = { 'prettier', 'injected' },
				css = { 'prettier' },
				vue = { 'prettier' },
				scss = { 'prettier' },
				less = { 'prettier' },
				graphql = { 'prettier' },
				lua = { 'stylua' },
				-- Ideally I'd use the LSP for this, but I'd lose organize imports and the autofix
				-- https://github.com/astral-sh/ruff/issues/12778#issuecomment-2279374570
				python = { 'ruff_fix', 'ruff_organize_imports', lsp_format = 'first' },
				go = {
					-- this will run gofmt too
					-- I'm using this instead of LSP format because it cleans up imports too
					'goimports',
				},
				nix = { 'alejandra', 'statix' },
				-- not 100% supported but does the job as long as I'm writing POSIX and not fancy zsh
				zsh = { 'shfmt' },
			}, js_formats),
			format_on_save = function(bufnr)
				-- Disable with a global or buffer-local variable
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				-- Disable autoformat for files in a certain path
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match '/node_modules/' then
					return
				end

				return { timeout_ms = 500, lsp_format = 'fallback' }
			end,
		},
		init = function()
			-- Use conform for gq.
			vim.opt.formatexpr = "v:lua.require'conform'.formatexpr()"

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
					lsp_format = 'fallback',
					range = range,
				}
			end, { range = true })
		end,
	},
}
