return {
	'https://github.com/nvim-treesitter/nvim-treesitter',
	branch = 'main',
	lazy = false,
	build = ':TSUpdate',
	dependencies = {
		{
			'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
			branch = 'main', -- must match treesitter branch,
		},
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
			ft = { 'html', 'javascriptreact', 'jsx', 'typescriptreact', 'tsx' },
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
						-- Only highlight react tags
						javascript = 'rainbow-tags-react',
						typescript = 'rainbow-tags-react',
						tsx = 'rainbow-tags-react',
						jsx = 'rainbow-tags-react',
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

		-- https://github.com/lewis6991/ts-install.nvim/issues/9#issuecomment-2924799227
		local treesitter = require 'nvim-treesitter'
		local ts_config = require 'nvim-treesitter.config'

		treesitter.setup {}

		vim.treesitter.language.register('markdown', 'mdx')
		vim.treesitter.language.register('bash', 'zsh')

		local ensure_installed = {
			'embedded_template', -- ERB, EJS, etc…
			'git_config',
			'gitattributes',
			'git_rebase',
			'diff',
			'gitcommit', -- requires git_rebase and diff https://github.com/gbprod/tree-sitter-gitcommit#note-about-injected-languages
			'gitignore',
			'jsdoc',
			'markdown',
			'markdown_inline',
			'query', -- For treesitter quereies
			'regex',
		}

		local syntax_map = {}

		local already_installed = ts_config.get_installed 'parsers'

		local parsers_to_install = vim
			.iter(ensure_installed)
			:filter(function(parser)
				return not vim.tbl_contains(already_installed, parser)
			end)
			:totable()

		if #parsers_to_install > 0 then
			treesitter.install(parsers_to_install)
		end

		local function ts_start(bufnr, parser_name)
			vim.treesitter.start(bufnr, parser_name)

			-- Use regex based syntax-highlighting as fallback as some plugins might need it
			if vim.bo[bufnr].filetype == 'markdown' then
				vim.bo[bufnr].syntax = 'ON'
			end

			-- Use treesitter for folds
			vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

			-- Use treesitter for indentation
			vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end

		-- Auto-install and start parsers for any buffer
		vim.api.nvim_create_autocmd({ 'BufRead', 'FileType' }, {
			desc = 'Enable Treesitter',
			callback = function(event)
				local bufnr = event.buf
				local filetype =
					vim.api.nvim_get_option_value('filetype', { buf = bufnr })

				-- Skip if no filetype
				if filetype == '' then
					return
				end

				-- Get parser name based on filetype
				local lang = vim.tbl_get(syntax_map, filetype)

				if lang == nil then
					lang = filetype
				else
					vim.notify('Using language override ' .. lang)
				end

				local parser_name = vim.treesitter.language.get_lang(lang)

				if not parser_name then
					vim.notify(
						vim.inspect('No treesitter parser found for filetype: ' .. lang),
						vim.log.levels.WARN
					)
					return
				end

				-- Try to get existing parser
				local parser_configs = require 'nvim-treesitter.parsers'
				if not parser_configs[parser_name] then
					return -- Parser not available, skip silently
				end

				local parser_exists =
					pcall(vim.treesitter.get_parser, bufnr, parser_name)

				if not parser_exists then
					-- Check if parser is already installed
					if vim.tbl_contains(already_installed, parser_name) then
						vim.notify(
							'Parser for ' .. parser_name .. ' already installed.',
							vim.log.levels.INFO
						)
					else
						-- If not installed, install parser asynchronously and start treesitter
						vim.notify(
							'Installing parser for ' .. parser_name,
							vim.log.levels.INFO
						)

						treesitter.install({ parser_name }):await(function()
							ts_start(bufnr, parser_name)
						end)

						return
					end
				end

				-- Start treesitter for this buffer
				ts_start(bufnr, parser_name)
			end,
		})
	end,
}
