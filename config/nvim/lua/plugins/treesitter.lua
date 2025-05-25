return {
	'https://github.com/nvim-treesitter/nvim-treesitter',
	branch = 'main',
	lazy = false,
	build = ':TSUpdate',
	dependencies = {
		{
			'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
			opts = {
				enable_autocmd = false,
			},
			init = function()
				local get_option = vim.filetype.get_option

				---@diagnostic disable-next-line: duplicate-set-field
				vim.filetype.get_option = function(filetype, option)
					return option == 'commentstring'
							and require('ts_context_commentstring.internal').calculate_commentstring()
						or get_option(filetype, option)
				end
			end,
		},
		{
			'https://github.com/HiPhish/rainbow-delimiters.nvim',
			config = function()
				require('rainbow-delimiters.setup').setup {
					enabled_when = function(bufnr)
						local max_filesize = 1 * 1024 * 1024 -- 1 MB
						local ok, stats =
							pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
						if ok and stats and stats.size > max_filesize then
							return false
						end
						return true
					end,
					whitelist = {
						'html',
						'javascript',
						'jsx',
						'typescript',
						'tsx',
					},
					query = {
						javascript = 'rainbow-tags-react',
						typescript = 'rainbow-tags-react',
						tsx = 'rainbow-tags-react',
						jsx = 'rainbow-tags-react',
					},
					highlight = {
						-- I reversed the default order, probably I might even change the
						-- colors completely
						'RainbowDelimiterCyan',
						'RainbowDelimiterViolet',
						'RainbowDelimiterGreen',
						'RainbowDelimiterOrange',
						'RainbowDelimiterBlue',
						'RainbowDelimiterYellow',
						'RainbowDelimiterRed',
					},
				}
			end,
		},
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
		require('nvim-treesitter').setup {
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
			highlight = {
				enable = true,
				use_languagetree = true,
				additional_vim_regex_highlighting = { 'markdown' }, -- for the obsidian style %% comments
			},
		}

		vim.treesitter.language.register('markdown', 'mdx')
		vim.treesitter.language.register('bash', 'zsh')
	end,
}
