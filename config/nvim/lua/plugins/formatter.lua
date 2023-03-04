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
	}
end

local function shfmt()
	return {
		exe = 'shfmt',
		args = { '-' },
		stdin = true,
	}
end

local filetype = {
	javascript = { prettier },
	typescript = { prettier },
	javascriptreact = { prettier },
	typescriptreact = { prettier },
	vue = { prettier },
	['javascript.jsx'] = { prettier },
	['typescript.tsx'] = { prettier },
	['javascript.jest'] = { prettier },
	['typescript.jest'] = { prettier },
	markdown = { prettier },
	['markdown.mdx'] = { prettier },
	mdx = { prettier },
	css = { prettier },
	json = { prettier },
	jsonc = { prettier },
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
		function()
			return {
				exe = 'rustfmt',
				args = { '--emit=stdout' },
				stdin = true,
			}
		end,
	},
	python = {
		function()
			return {
				exe = 'ruff',
				args = { '--fix', '-' },
				stdin = true,
			}
		end,
	},
	go = {
		function()
			-- this will run gofmt too
			return {
				exe = 'goimports',
				args = { '-w', vim.api.nvim_buf_get_name(0) },
				stdin = false,
			}
		end,
	},
	nix = {
		function()
			return {
				exe = 'nixpkgs-fmt',
				stdin = true,
			}
		end,
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
}

return {
	'https://github.com/mhartington/formatter.nvim',
	cmd = { 'FormatWrite' },
	opts = {
		logging = false,
		filetype = filetype,
	},
}
