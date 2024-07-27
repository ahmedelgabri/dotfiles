return {
	'https://github.com/nvim-treesitter/nvim-treesitter',
	event = { 'BufReadPost' },
	build = ':TSUpdate',
	dependencies = {
		{
			'https://github.com/MeanderingProgrammer/markdown.nvim',
			config = function()
				require('render-markdown').setup {}
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
		local has_treesitter = pcall(require, 'nvim-treesitter')

		if not has_treesitter then
			return
		end

		local parsers = require 'nvim-treesitter.parsers'

		local is_big_file = function(_, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats =
				pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf or 0))
			return ok and stats and stats.size > max_filesize
		end

		-- See https://github.com/andreaswachowski/dotfiles/commit/853fbc1e06595ecd18490cdfad64823be8bb9971
		--- @diagnostic disable-next-line: missing-fields
		require('nvim-treesitter.configs').setup {
			sync_install = false,
			auto_install = true,
			ensure_installed = {
				'bash',
				'css',
				'embedded_template', -- ERB, EJS, etc…
				'html',
				'go',
				'javascript',
				'jsdoc',
				'json',
				'jsonc',
				'lua',
				'markdown',
				'markdown_inline',
				'nix',
				'python',
				'query', -- For treesitter quereies
				'regex',
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
				disable = function(lang, buf)
					return lang == 'org' or is_big_file(buf)
				end,
				-- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
				-- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/h57kxuv/?context=3
				-- Required since TS highlighter doesn't support all syntax features (conceal)
				additional_vim_regex_highlighting = {
					'org',
				},
			},
		}

		vim.treesitter.language.register('markdown', 'mdx')
		vim.treesitter.language.register('bash', 'zsh')

		vim.treesitter.query.add_directive(
			'offset-first-n!',
			function(match, _, _, pred, metadata)
				---@cast pred integer[]
				local capture_id = pred[2]
				if not metadata[capture_id] then
					metadata[capture_id] = {}
				end

				local range = metadata[capture_id].range
					---@diagnostic disable-next-line: undefined-field
					or { match[capture_id]:range() }
				local offset = pred[3] or 0

				range[4] = range[2] + offset
				metadata[capture_id].range = range
			end,
			true
		)

		local non_filetype_match_injection_language_aliases = {
			ex = 'elixir',
			pl = 'perl',
			bash = 'sh', -- reversing these two from the treesitter source
			uxn = 'uxntal',
			ts = 'typescript',
			js = 'javascript',
			tsx = 'typescriptreact',
			jsx = 'javascriptreact',
			py = 'python',
			rb = 'ruby',
			md = 'markdown',
			html5 = 'html',
			scss = 'sass',
		}

		-- https://fabrizioschiavi.github.io/pragmatapro-semiotics/
		local icons = {
			mermaid = '󰈺 ',
			plantuml = ' ',
			chart = ' ',
			javascript = '󰌞 ',
			javascriptreact = '󰌞 ',
			typescript = '󰛦 ',
			typescriptreact = '󰛦 ',
			python = '󰌠 ',
			ruby = ' ',
			json = ' ',
			json5 = ' ',
			jsonc = ' ',
			markdown = ' ',
			html = '󰌝 ',
			go = '󰟓 ',
			php = ' ',
			swift = '󰛥 ',
			nix = '󱄅 ',
			css = '󰌜 ',
			sass = ' ',
			less = ' ',
			xml = '󰗀 ',
			r = '󰟔 ',
			rust = '󱘗 ',
			lua = '󰢱 ',
			kotlin = '󱈙 ',
			java = ' ',
			conf = ' ',
			toml = ' ',
			clojure = ' ',
			wasm = ' ',
			zsh = '󱆃 ',
			console = '󰞷 ',
		}

		vim.treesitter.query.add_directive(
			'ft-conceal!',
			function(match, _, source, pred, metadata)
				---@cast pred integer[]
				local capture_id = pred[2]
				if not metadata[capture_id] then
					metadata[capture_id] = {}
				end

				local node = match[pred[2]]
				local node_text = vim.treesitter.get_node_text(node, source)

				local ft = vim.filetype.match { filename = 'a.' .. node_text }
				node_text = ft
					or non_filetype_match_injection_language_aliases[node_text]
					or node_text

				metadata.conceal = icons[node_text] or '󰡯 '
			end,
			true
		)
	end,
}
