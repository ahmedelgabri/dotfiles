local utils = require '_.utils'

return {
	'https://github.com/nvim-treesitter/nvim-treesitter',
	event = utils.LazyFile,
	build = ':TSUpdate',
	dependencies = {
		{
			'https://github.com/windwp/nvim-ts-autotag',
			opts = {
				opts = {
					enable_close = true, -- Auto close tags
					enable_rename = true, -- Auto rename pairs of tags
					enable_close_on_slash = true, -- Auto close on trailing </
				},
			},
		},
	},
	config = function()
		-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3356#issuecomment-1226348556
		-- N.B! CC needs to be unset (not set to clang as in nix shells)
		vim.env.CC = ''

		-- See https://github.com/andreaswachowski/dotfiles/commit/853fbc1e06595ecd18490cdfad64823be8bb9971
		--- @diagnostic disable-next-line: missing-fields
		require('nvim-treesitter.configs').setup {
			sync_install = false,
			auto_install = true,
			ensure_installed = {
				'bash',
				'css',
				'diff',
				'embedded_template', -- ERB, EJS, etc…
				'git_config',
				'git_rebase',
				'gitattributes',
				'gitcommit', -- requires git_rebase and diff
				'gitignore',
				'go',
				'html',
				'ini',
				'javascript',
				'jsdoc',
				'json',
				'jsonc',
				'lua',
				'make',
				'markdown',
				'markdown_inline',
				'muttrc',
				'nix',
				'python',
				'query', -- For treesitter quereies
				'regex',
				'ssh_config',
				'tmux',
				'toml',
				'tsx',
				'typescript',
				'vim',
				'vimdoc',
				'yaml',
			},
			indent = {
				enable = true,
			},
			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { 'BufWrite', 'CursorHold' },
			},
			highlight = {
				enable = true,
				use_languagetree = true,
			},
		}

		vim.treesitter.language.register('markdown', 'mdx')
		vim.treesitter.language.register('bash', 'zsh')
	end,
}
