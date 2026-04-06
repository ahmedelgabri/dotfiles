-- Treesitter and related plugins (eager)
local pack = require 'plugins.pack'

-- ts-context-commentstring setup
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

-- nvim-ts-autotag setup
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

-- rainbow-delimiters: lazy on filetype
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'html', 'javascriptreact', 'jsx', 'typescriptreact', 'tsx' },
	callback = function()
		if
			not pack.setup('rainbow-delimiters.nvim', function()
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
				end
			)
		then
			return
		end
	end,
})

-- Treesitter config
do
	-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3356#issuecomment-1226348556
	-- N.B! CC needs to be unset (not set to clang as in nix shells)
	vim.env.CC = ''

	-- https://github.com/lewis6991/ts-install.nvim/issues/9#issuecomment-2924799227
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
	}

	local function has_installed_parser(parser_name)
		return vim.tbl_contains(ts_config.get_installed 'parsers', parser_name)
	end

	local parsers_to_install = vim
		.iter(ensure_installed)
		:filter(function(parser)
			return not has_installed_parser(parser)
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
			local lang = filetype

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

			local parser = vim.treesitter.get_parser(bufnr, parser_name)

			if parser == nil then
				if has_installed_parser(parser_name) then
					vim.notify(
						'Unable to create parser for ' .. parser_name,
						vim.log.levels.WARN
					)
					return
				end

				-- If not installed, install parser asynchronously and start treesitter
				vim.notify('Installing parser for ' .. parser_name, vim.log.levels.INFO)

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

			-- Start treesitter for this buffer
			ts_start(bufnr, parser_name)
		end,
	})
end
