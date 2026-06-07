local pack = require '_.pack'

pack.add {
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter',
		version = 'main',
		event = { 'BufRead', 'FileType' },
		config = function(event)
			-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3356#issuecomment-1226348556
			-- N.B! CC needs to be unset (not set to clang as in nix shells)
			vim.env.CC = ''

			vim.cmd.packadd 'nvim-treesitter-textobjects'
			vim.cmd.packadd 'nvim-ts-context-commentstring'
			vim.cmd.packadd 'nvim-ts-autotag'

			require('ts_context_commentstring').setup {
				enable_autocmd = false,
			}

			do
				local get_option = vim.filetype.get_option

				---@diagnostic disable-next-line: duplicate-set-field
				vim.filetype.get_option = function(filetype, option)
					return option == 'commentstring'
							and require('ts_context_commentstring.internal').calculate_commentstring()
						or get_option(filetype, option)
				end
			end

			require('nvim-ts-autotag').setup {
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
				per_filetype = {
					html = { enable_rename = false },
					javascriptreact = { enable_rename = false },
					['javascript.jsx'] = { enable_rename = false },
					typescriptreact = { enable_rename = false },
					['typescript.tsx'] = { enable_rename = false },
					xml = { enable_rename = false },
				},
			}

			local treesitter = require 'nvim-treesitter'
			local ts_config = require 'nvim-treesitter.config'

			treesitter.setup {}

			local ensure_installed = {
				'embedded_template', -- ERB, EJS, etc…
				'git_config',
				'gitattributes',
				'git_rebase',
				'diff',
				'gitcommit', -- requires git_rebase and diff https://github.com/gbprod/tree-sitter-gitcommit#note-about-injected-languages
				'gitignore',
				'jsdoc',
				'query', -- For treesitter quereies
				'regex',
				'yaml', -- needed for markdown frontmatter injection
			}

			local parsers_to_install = vim
				.iter(ensure_installed)
				:filter(function(parser)
					return not vim.tbl_contains(ts_config.get_installed 'parsers', parser)
				end)
				:totable()

			if #parsers_to_install > 0 then
				treesitter.install(parsers_to_install)
			end

			local function ts_start(bufnr, parser_name)
				vim.treesitter.start(bufnr, parser_name)

				-- Don't enable tree-sitter features in bigfiles
				if vim.bo[bufnr].filetype ~= 'bigfile' then
					-- Use regex based syntax-highlighting as fallback as some plugins might need it
					if vim.bo[bufnr].filetype == 'markdown' then
						vim.bo[bufnr].syntax = 'ON'
					end

					-- Use treesitter for folds
					vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

					-- Use treesitter for indentation
					vim.bo[bufnr].indentexpr =
						"v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end

			local function start_for_buffer(ev)
				local bufnr = ev.buf
				local filetype =
					vim.api.nvim_get_option_value('filetype', { buf = bufnr })

				if filetype == '' then
					return
				end

				local parser_name = vim.treesitter.language.get_lang(filetype)
				if not parser_name then
					vim.notify(
						vim.inspect('No treesitter parser found for filetype: ' .. filetype),
						vim.log.levels.WARN
					)
					return
				end

				local parser_configs = require 'nvim-treesitter.parsers'
				if not parser_configs[parser_name] then
					return
				end

				local parser = vim.treesitter.get_parser(bufnr, parser_name)

				if parser == nil then
					if
						vim.tbl_contains(ts_config.get_installed 'parsers', parser_name)
					then
						vim.notify(
							'Unable to create parser for ' .. parser_name,
							vim.log.levels.WARN
						)
						return
					end

					vim.notify(
						'Installing parser for ' .. parser_name,
						vim.log.levels.INFO
					)

					treesitter.install({ parser_name }):await(function()
						if vim.treesitter.get_parser(bufnr, parser_name) == nil then
							vim.notify(
								'Unable to create parser for ' .. parser_name,
								vim.log.levels.WARN
							)
							return
						end

						ts_start(bufnr, parser_name)
					end)

					return
				end

				ts_start(bufnr, parser_name)
			end

			vim.api.nvim_create_autocmd({ 'BufRead', 'FileType' }, {
				group = vim.api.nvim_create_augroup('custom_treesitter_start', {
					clear = true,
				}),
				callback = start_for_buffer,
			})

			start_for_buffer(event)
		end,
		build = function()
			vim.cmd 'TSUpdate'
		end,
	},
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
		version = 'main',
		load = false,
	},
	{
		src = 'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
		load = false,
	},
	{ src = 'https://github.com/windwp/nvim-ts-autotag', load = false },
	{
		src = 'https://github.com/HiPhish/rainbow-delimiters.nvim',
		ft = { 'html', 'javascriptreact', 'jsx', 'typescriptreact', 'tsx' },
		config = function()
			require('rainbow-delimiters.setup').setup {
				enabled_when = function(bufnr)
					local max_filesize = 1 * 1024 * 1024 -- 1 MB
					local ok, stats =
						pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
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
}
