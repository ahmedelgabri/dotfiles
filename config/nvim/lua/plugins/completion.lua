local has_words_before = function()
	if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
		return false
	end
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0
		and vim.api
				.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]
				:match '^%s*$'
			== nil
end

---@diagnostic disable: missing-fields

return {
	'https://github.com/hrsh7th/nvim-cmp',
	event = 'InsertEnter',
	dependencies = {
		{ 'https://github.com/hrsh7th/cmp-nvim-lsp' },
		{ 'https://github.com/saadparwaiz1/cmp_luasnip' },
		{ 'https://github.com/hrsh7th/cmp-path' },
		{ 'https://github.com/hrsh7th/cmp-buffer' },
		{ 'https://github.com/hrsh7th/cmp-emoji' },
		{ 'https://github.com/f3fora/cmp-spell' },
		{ 'https://github.com/hrsh7th/cmp-nvim-lsp-signature-help' },
		{ 'https://github.com/roobert/tailwindcss-colorizer-cmp.nvim' },
	},
	config = function()
		local utils = require '_.utils'

		local completion_loaded = pcall(function()
			local cmp = require 'cmp'
			local types = require 'cmp.types'
			local str = require 'cmp.utils.str'
			local luasnip = require 'luasnip'
			local cmp_tailwind = require 'tailwindcss-colorizer-cmp'

			cmp.setup {
				experimental = {
					ghost_text = true,
				},
				view = {
					-- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#custom-menu-direction
					entries = {
						name = 'custom',
						selection_order = 'near_cursor',
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
						-- if
						-- 	entry.completion_item.insertTextFormat
						-- 	== types.lsp.InsertTextFormat.Snippet
						-- then
						-- 	-- parse_snippet is deprecated, need to find an alternative
						-- 	word = vim.lsp.util.parse_snippet(word)
						-- end
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

						vim_item.kind = string.format(
							'%s %s',
							require('mini.icons').get('lsp', vim_item.kind),
							vim_item.kind
						)

						local strings = vim.split(vim_item.kind, ' ', { trimempty = true })

						vim_item.kind = (strings[1] or '') .. ' '
						cmp_tailwind.formatter(entry, vim_item)

						return vim_item
					end,
				},
				window = {
					completion = cmp.config.window.bordered {
						border = utils.get_border(),
						winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,Search:None',
						winblend = 0,
						scrollbar = false,
					},
					documentation = cmp.config.window.bordered {
						border = utils.get_border(),
						winhighlight = 'Nomral:Normal,FloatBorder:Pmenu,Search:None',
						winblend = 0,
						scrollbar = false,
					},
				},
				completion = {
					completeopt = 'menu,menuone,noinsert',
				},
				sources = cmp.config.sources({
					{ name = utils.is_work_machine() and 'copilot' or 'supermaven' },
					{ name = 'luasnip' },
					{ name = 'nvim_lsp' },
					{ name = 'path' },
					{ name = 'nvim_lsp_signature_help' },
				}, {
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
					{ name = 'emoji' },
				}),
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert {
					['<C-n>'] = cmp.mapping.select_next_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-p>'] = cmp.mapping.select_prev_item {
						behavior = cmp.SelectBehavior.Insert,
					},
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
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
						if cmp.visible() and has_words_before() then
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
