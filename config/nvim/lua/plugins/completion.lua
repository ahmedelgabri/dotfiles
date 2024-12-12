local utils = require '_.utils'

local has_words_before = function()
	if vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'prompt' then
		return false
	end
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0
		and vim.api
				.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]
				:match '^%s*$'
			== nil
end

return {

	{ 'https://github.com/saadparwaiz1/cmp_luasnip' },
	{ 'https://github.com/hrsh7th/cmp-emoji', lazy = true },
	{ 'https://github.com/giuxtaposition/blink-cmp-copilot' },
	{
		'https://github.com/saghen/blink.compat',
		opts = { impersonate_nvim_cmp = true },
	},
	{
		'https://github.com/Saghen/blink.cmp',
		event = { 'VeryLazy' },
		-- version = 'v0.*',
		build = 'nix run .#build-plugin',
		opts = {
			keymap = {
				preset = 'default',
				['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
				['<Tab>'] = {
					function(cmp)
						if not has_words_before() then
							return
						end

						if cmp.snippet_active() then
							return cmp.accept()
						else
							return cmp.select_next()
						end
					end,
					'snippet_forward',
					'fallback',
				},
				['<CR>'] = { 'accept', 'fallback' },
			},

			snippets = {
				expand = function(snippet)
					require('luasnip').lsp_expand(snippet)
				end,
				active = function(filter)
					if filter and filter.direction then
						return require('luasnip').jumpable(filter.direction)
					end
					return require('luasnip').in_snippet()
				end,
				jump = function(direction)
					require('luasnip').jump(direction)
				end,
			},

			completion = {
				accept = {
					-- Experimental auto-brackets support
					auto_brackets = {
						enabled = true,
					},
				},

				menu = {
					border = utils.get_border(),
					draw = {
						components = {
							kind_icon = {
								text = function(ctx)
									local MiniIcons = require 'mini.icons'
									local source = ctx.item.source_name
									local label = ctx.item.label
									local icon = source == 'LSP'
											and MiniIcons.get('lsp', ctx.kind)
										or source == 'copilot' and MiniIcons.get('lsp', source)
										or source == 'Path' and (label:match '%.[^/]+$' and MiniIcons.get(
											'file',
											label
										) or MiniIcons.get('directory', ctx.item.label))
										or ctx.kind_icon

									return icon .. ' '
								end,
							},
						},
					},
				},

				documentation = {
					auto_show = true,
					window = {
						border = utils.get_border(),
					},
				},
				ghost_text = {
					enabled = true,
				},
			},

			-- Experimental signature help support
			signature = {
				enabled = true,
				window = {
					border = utils.get_border(),
				},
			},

			sources = {
				default = {
					'lsp',
					'luasnip',
					'path',
					'snippets',
					'buffer',
					'lazydev',
					'emoji',
				},
				providers = {
					-- dont show LuaLS require statements when lazydev has items
					lsp = { fallbacks = { 'lazydev' } },
					lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink' },
					emoji = {
						name = 'emoji',
						module = 'blink.compat.source',
						transform_items = function(_ctx, items)
							local kind = require('blink.cmp.types').CompletionItemKind.Text

							for i = 1, #items do
								items[i].kind = kind
							end

							return items
						end,
					},
				},
			},
		},
		config = function(_, opts)
			local ok = pcall(require, 'copilot.api')

			if ok then
				table.insert(opts.sources.default, 'copilot')
				opts.sources.providers.copilot = {
					name = 'copilot',
					module = 'blink-cmp-copilot',
				}
			end

			require('blink.cmp').setup(opts)
		end,
	},
}
