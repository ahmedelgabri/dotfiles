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
	{
		'https://github.com/Saghen/blink.cmp',
		event = { 'VeryLazy' },
		-- version = 'v0.*',
		build = 'nix run .#build-plugin',
		dependencies = {
			'https://github.com/saadparwaiz1/cmp_luasnip',
			{ 'https://github.com/hrsh7th/cmp-emoji', lazy = true },
			{ 'https://github.com/roobert/tailwindcss-colorizer-cmp.nvim' },
			{
				'https://github.com/saghen/blink.compat',
				opts = { impersonate_nvim_cmp = true },
			},
		},
		opts = {
			accept = {
				expand_snippet = function(snippet)
					require('luasnip').lsp_expand(snippet)
				end,
				-- experimental auto-brackets support
				auto_brackets = { enabled = true },
			},
			-- experimental signature help support
			trigger = { signature_help = { enabled = true } },
			keymap = {
				preset = 'default',
				['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
				['<Tab>'] = {
					function(cmp)
						if not has_words_before() then
							return
						end

						if cmp.is_in_snippet() then
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
			windows = {
				ghost_text = {
					enabled = false, -- So copilot works
				},
				documentation = {
					border = utils.get_border(),
					auto_show = true,
				},
				signature_help = {
					border = utils.get_border(),
				},
				autocomplete = {
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
				highlight = {
					use_nvim_cmp_as_default = true,
				},
			},
			sources = {
				completion = {
					enabled_providers = {
						'lsp',
						'luasnip',
						'path',
						'snippets',
						'buffer',
						'lazydev',
						'emoji',
					},
				},
				providers = {
					-- dont show LuaLS require statements when lazydev has items
					lsp = { fallback_for = { 'lazydev' } },
					lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink' },
					luasnip = {
						name = 'luasnip',
						module = 'blink.compat.source',
						score_offset = -3,
						opts = {
							use_show_condition = false,
							show_autosnippets = true,
						},
					},
					emoji = {
						name = 'emoji',
						module = 'blink.compat.source',
						transform_items = function(_ctx, items)
							-- TODO: check https://github.com/Saghen/blink.cmp/pull/253#issuecomment-2454984622
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
	},
}
