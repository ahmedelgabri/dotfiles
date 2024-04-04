return {
	'https://github.com/hrsh7th/nvim-cmp',
	event = 'InsertEnter',
	dependencies = {
		{ 'https://github.com/hrsh7th/cmp-nvim-lsp' },
		{ 'https://github.com/andersevenrud/cmp-tmux' },
		{ 'https://github.com/saadparwaiz1/cmp_luasnip' },
		{ 'https://github.com/hrsh7th/cmp-path' },
		{ 'https://github.com/hrsh7th/cmp-buffer' },
		{ 'https://github.com/hrsh7th/cmp-emoji' },
		{ 'https://github.com/f3fora/cmp-spell' },
		{ 'https://github.com/hrsh7th/cmp-cmdline' },
		{ 'https://github.com/hrsh7th/cmp-calc' },
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

			calc = '󰃬 ',
		}

		local completion_loaded = pcall(function()
			local cmp = require 'cmp'
			local types = require 'cmp.types'
			local str = require 'cmp.utils.str'
			local luasnip = require 'luasnip'

			cmp.setup {
				experimental = {
					ghost_text = false, -- this feature conflict with copilot.vim's preview.
				},
				view = {
					entries = {
						follow_cursor = true,
					},
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
				formatting = {
					fields = { 'kind', 'abbr' },
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

						if entry.source.name == 'calc' then
							-- Get the custom icon for 'calc' source
							-- Replace the kind glyph with the custom icon
							vim_item.kind = icons.calc
						else
							vim_item.kind =
								string.format('%s %s', icons[vim_item.kind], vim_item.kind)
						end

						local strings = vim.split(vim_item.kind, ' ', { trimempty = true })

						vim_item.kind = (strings[1] or '') .. ' '

						return vim_item
					end,
				},
				window = {
					completion = cmp.config.window.bordered {
						border = 'rounded',
						winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,Search:None',
						col_offset = -3,
						side_padding = 0,
						scrollbar = false,
					},
					documentation = cmp.config.window.bordered {
						border = 'rounded',
						winhighlight = 'Nomral:Normal,FloatBorder:Pmenu,Search:None',
						col_offset = -3,
						side_padding = 0,
						scrollbar = false,
					},
				},
				completion = {
					completeopt = 'menu,menuone,noinsert',
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
				sources = cmp.config.sources({
					{ name = 'luasnip' },
					{ name = 'nvim_lsp' },
					{ name = 'git' },
					{ name = 'path' },
					{ name = 'nvim_lsp_signature_help' },
				}, {
					{ name = 'calc' },
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
					{ name = 'emoji' },
					{ name = 'spell' },
				}),
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert {
					-- For copilot
					['<C-g>'] = cmp.mapping(function(_)
						vim.api.nvim_feedkeys(
							vim.fn['copilot#Accept'](
								vim.api.nvim_replace_termcodes('<Tab>', true, true, true)
							),
							'n',
							true
						)
					end),
					['<C-n>'] = cmp.mapping.select_next_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-p>'] = cmp.mapping.select_prev_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
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
