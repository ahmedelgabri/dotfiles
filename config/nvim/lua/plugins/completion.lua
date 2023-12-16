return {
	'https://github.com/hrsh7th/nvim-cmp',
	dependencies = {
		{ 'https://github.com/hrsh7th/cmp-nvim-lsp' },
		{ 'https://github.com/andersevenrud/cmp-tmux' },
		{ 'https://github.com/saadparwaiz1/cmp_luasnip' },
		{ 'https://github.com/hrsh7th/cmp-path' },
		{ 'https://github.com/hrsh7th/cmp-buffer' },
		{ 'https://github.com/hrsh7th/cmp-emoji' },
		{ 'https://github.com/f3fora/cmp-spell' },
		{ 'https://github.com/hrsh7th/cmp-cmdline' },
		{
			'https://github.com/petertriho/cmp-git',
			dependencies = {
				'https://github.com/nvim-lua/plenary.nvim',
			},
			opts = {
				filetypes = { 'gitcommit', 'octo' },
			},
		},
		{ 'https://github.com/hrsh7th/cmp-nvim-lsp-signature-help' },
	},
	config = function()
		local utils = require '_.utils'

		local has_words_before = function()
			if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
				return false
			end
			local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			return col ~= 0
				and vim.api
						.nvim_buf_get_lines(0, line - 1, line, true)[1]
						:sub(col, col)
						:match '%s'
					== nil
		end

		local sources = {
			{ name = 'luasnip' },
			{ name = 'nvim_lsp' },
			{ name = 'git' },
			{ name = 'path' },
			{ name = 'nvim_lsp_signature_help' },
			{ name = 'conjure' },
			{
				name = 'buffer',
				max_item_count = 10,
				keyword_length = 5,
				option = {
					-- https://github.com/hrsh7th/cmp-buffer#get_bufnrs-type-fun-number=
					-- https://github.com/hrsh7th/cmp-buffer#performance-on-large-text-files=
					get_bufnrs = function()
						local LIMIT = 1024 * 1024 -- 1 Megabyte max
						local bufs = {}

						for _, buf in ipairs(vim.api.nvim_list_bufs()) do
							local line_count = vim.api.nvim_buf_line_count(buf)
							local byte_size = vim.api.nvim_buf_get_offset(buf, line_count)

							if byte_size < LIMIT then
								bufs[buf] = true
							end
						end

						return vim.tbl_keys(bufs)
					end,
				},
			},
			{ name = 'tmux', max_item_count = 10 },
			{ name = 'orgmode' },
			{ name = 'emoji' },
			{ name = 'spell' },
		}

		local menu = {}
		local special_menu_case = {
			nvim_lsp = 'LSP',
			luasnip = 'Snip',
			orgmode = 'Org',
			nvim_lsp_signature_help = 'LSP',
		}

		for _, source in ipairs(sources) do
			menu[source.name] = string.format(
				'「%s」',
				special_menu_case[source.name] or utils.firstToUpper(source.name)
			)
		end

		local icons = {
			Array = ' ',
			Boolean = '◩ ',
			Class = ' ',
			Color = ' ',
			Constant = ' ',
			-- Constructor = ' ',
			Constructor = ' ',
			Enum = ' ',
			EnumMember = ' ',
			Event = ' ',
			Field = ' ',
			File = ' ',
			Folder = ' ',
			Function = ' ',
			-- Interface = ' ',
			Interface = '練',
			Key = ' ',
			Keyword = ' ',
			Method = ' ',
			Module = ' ',
			Namespace = ' ',
			Null = 'ﳠ ',
			Number = ' ',
			Object = ' ',
			Operator = ' ',
			Package = ' ',
			Property = ' ',
			Reference = ' ',
			Snippet = ' ',
			String = ' ',
			Struct = ' ',
			Text = ' ',
			TypeParameter = ' ',
			Unit = '塞 ',
			Value = ' ',
			Variable = ' ',
		}

		local completion_loaded = pcall(function()
			local cmp = require 'cmp'
			local types = require 'cmp.types'
			local str = require 'cmp.utils.str'
			local luasnip = require 'luasnip'

			--- @diagnostic disable-next-line: missing-fields
			cmp.setup {
				experimental = {
					ghost_text = true,
				},
				bufIsBig = function(bufnr)
					local max_filesize = 300 * 1024 -- 300 KB
					local ok, stats =
						pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
					if ok and stats and stats.size > max_filesize then
						return true
					else
						return false
					end
				end,
				--- @diagnostic disable-next-line: missing-fields
				formatting = {
					format = function(entry, vim_item)
						-- Get the full snippet (and only keep first line)
						local word = entry:get_insert_text()
						if
							entry.completion_item.insertTextFormat
							== types.lsp.InsertTextFormat.Snippet
						then
							word = vim.lsp.util.parse_snippet(word)
						end
						word = str.oneline(word)

						-- concatenates the string
						-- local max = 50
						-- if string.len(word) >= max then
						-- 	local before = string.sub(word, 1, math.floor((max - 3) / 2))
						-- 	word = before .. "..."
						-- end

						if
							entry.completion_item.insertTextFormat
								== types.lsp.InsertTextFormat.Snippet
							and string.sub(vim_item.abbr, -1, -1) == '~'
						then
							word = word .. '~'
						end

						vim_item.abbr = word

						vim_item.kind =
							string.format('%s %s', icons[vim_item.kind], vim_item.kind)

						vim_item.menu = menu[entry.source.name] or ''

						return vim_item
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				completion = {
					completeopt = 'menu,menuone,noinsert',
					-- https://github.com/hrsh7th/nvim-cmp/issues/101#issuecomment-907918888
					get_trigger_characters = function(trigger_characters)
						local filter_characters = function(char)
							return char ~= ' ' and char ~= '\t'
						end
						return vim.tbl_filter(filter_characters, trigger_characters)
					end,
				},
				sorting = {
					comparators = {
						-- defaults https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
						cmp.config.compare.locality,
						cmp.config.compare.recently_used,
						cmp.config.compare.score,
						cmp.config.compare.offset,
						cmp.config.compare.order,
						cmp.config.compare.exact,
						cmp.config.compare.scopes,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
					},
				},
				sources = cmp.config.sources(sources),
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = {
					['<C-n>'] = cmp.mapping.select_next_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-p>'] = cmp.mapping.select_prev_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
					['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
					['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
					['<C-e>'] = cmp.mapping(function(fallback)
						if cmp.abort() then
							return
						elseif luasnip.choice_active() then
							luasnip.change_choice(1)
						else
							fallback()
						end
					end, {
						'i',
						's',
					}),
					['<CR>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Insert,
						select = true,
					},
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, {
						'i',
						's',
					}),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item { behavior = cmp.SelectBehavior.Select }
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, {
						'i',
						's',
					}),
				},
			}
		end)

		if not completion_loaded then
			utils.notify 'Completion failed to set up'
		end
	end,
}
