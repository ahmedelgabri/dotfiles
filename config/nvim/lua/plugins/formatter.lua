local function prettier()
	return {
		exe = 'prettier',
		args = {
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
			vim.bo.textwidth <= 80 and 80 or vim.bo.textwidth,
			'--stdin-filepath',
			vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
		},
		stdin = true,
		try_node_modules = true,
	}
end

local function shfmt()
	return {
		exe = 'shfmt',
		stdin = true,
	}
end

return {
	'https://github.com/mhartington/formatter.nvim',
	cmd = { 'FormatWrite' },
	opts = function()
		local jsFormatter = vim.fn.executable 'deno' ~= 0
				and require('formatter.filetypes.typescript').denofmt
			or prettier

		return {
			logging = false,
			log_level = vim.log.levels.WARN,
			filetype = {
				javascript = { jsFormatter },
				typescript = { jsFormatter },
				javascriptreact = { jsFormatter },
				['javascriptreact.jest'] = { jsFormatter },
				typescriptreact = { jsFormatter },
				['typescriptreact.jest'] = { jsFormatter },
				['javascript.jsx'] = { jsFormatter },
				['typescript.tsx'] = { jsFormatter },
				['javascript.jest'] = { jsFormatter },
				['typescript.jest'] = { jsFormatter },
				json = { jsFormatter },
				jsonc = { jsFormatter },
				markdown = { jsFormatter },
				['markdown.mdx'] = { prettier },
				mdx = { prettier },
				css = { prettier },
				vue = { prettier },
				scss = { prettier },
				less = { prettier },
				yaml = { prettier },
				graphql = { prettier },
				html = { prettier },
				sh = { shfmt },
				bash = { shfmt },
				reason = {
					function()
						return {
							exe = 'refmt',
							stdin = true,
						}
					end,
				},
				rust = {
					require('formatter.filetypes.rust').rustfmt,
				},
				python = {
					require('formatter.filetypes.python').ruff,
				},
				go = {
					-- this will run gofmt too
					require('formatter.filetypes.go').goimports,
				},
				nix = {
					require('formatter.filetypes.nix').nixpkgs_fmt,
					function()
						return {
							exe = 'statix fix --stdin',
							stdin = true,
						}
					end,
				},
				lua = {
					function()
						return {
							exe = 'stylua',
							args = {
								'--sort-requires',
								'--line-endings',
								'Unix',
								'--quote-style',
								'AutoPreferSingle',
								'--call-parentheses',
								'None',
								'--indent-width',
								vim.bo.tabstop,
								'--column-width',
								vim.bo.textwidth,
								'-',
							},
							stdin = true,
						}
					end,
				},
				toml = {
					require('formatter.filetypes.toml').taplo,
				},
			},
		}
	end,
}
