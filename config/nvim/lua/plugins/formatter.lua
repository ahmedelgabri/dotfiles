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
	'astro',
} do
	js_formats[ft] = {
		'oxfmt',
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
			log_level = vim.log.levels.DEBUG,
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
					'oxfmt',
					'deno_fmt',
					'prettier',
					'jq',
					stop_after_first = true,
				},
				jsonc = {
					'oxfmt',
					'deno_fmt',
					'prettier',
					stop_after_first = true,
				},
				markdown = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier', 'deno_fmt'), 'injected' }
				end,
				['markdown.mdx'] = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier', 'deno_fmt'), 'injected' }
				end,

				mdx = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier'), 'injected' }
				end,
				html = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier'), 'injected' }
				end,
				xml = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier'), 'injected' }
				end,
				yaml = function(bufnr)
					return { first(bufnr, 'oxfmt', 'prettier'), 'injected' }
				end,
				css = { 'oxfmt', 'prettier', stop_after_first = true },
				vue = { 'oxfmt', 'prettier', stop_after_first = true },
				scss = { 'oxfmt', 'prettier', stop_after_first = true },
				less = { 'oxfmt', 'prettier', stop_after_first = true },
				graphql = { 'oxfmt', 'prettier', stop_after_first = true },
				lua = { 'stylua' },
				-- Ideally I'd use the LSP for this, but I'd lose organize imports and the autofix
				-- https://github.com/astral-sh/ruff/issues/12778#issuecomment-2279374570
				python = { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
				go = {
					-- this will run gofmt too
					-- I'm using this instead of LSP format because it cleans up imports too
					'goimports',
				},
				nix = { 'alejandra', 'statix' },
				-- not 100% supported but does the job as long as I'm writing POSIX and not fancy zsh
				zsh = { 'shfmt' },
				sh = { 'shfmt' },
				bash = { 'shfmt' },
				toml = { 'taplo' },
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

				-- Fall back to language-specific formatters
				return { timeout_ms = 500, lsp_format = 'fallback' }
			end,
		},
		init = function()
			-- Use conform for gq.
			vim.bo.formatexpr = "v:lua.require'conform'.formatexpr()"

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
			end, {
				range = true,
			})

			vim.api.nvim_create_user_command('FormatToggle', function(args)
				-- FormatToggle! will toggle formatting globally
				if args.bang then
					if vim.g.disable_autoformat == true then
						vim.g.disable_autoformat = nil
					else
						vim.g.disable_autoformat = true
					end
				else
					if vim.b.disable_autoformat == true then
						vim.b.disable_autoformat = nil
					else
						vim.b.disable_autoformat = true
					end
				end
			end, {
				desc = 'Toggle autoformat-on-save',
				bang = true,
			})
		end,
	},
}
