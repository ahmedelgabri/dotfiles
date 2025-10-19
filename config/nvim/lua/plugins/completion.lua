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

local function get_mini_icon_info(ctx)
	local MiniIcons = require 'mini.icons'
	local source = ctx.item.source_name
	local label = ctx.item.label

	if source == nil then
		return
	end

	if source == 'path' then
		if label:match '%.[^/]+$' then
			return MiniIcons.get('file', label)
		end

		return MiniIcons.get('directory', ctx.item.label)
	end

	return MiniIcons.get('lsp', ctx.kind)
end

local function get_icon(ctx)
	local icon = get_mini_icon_info(ctx)

	return icon or ctx.kind_icon
end

local function get_icon_highlight(ctx)
	local _, hl, _ = get_mini_icon_info(ctx)

	return hl
end

return {
	{
		'https://github.com/Saghen/blink.cmp',
		dependencies = {
			'https://github.com/rafamadriz/friendly-snippets',
			'https://github.com/moyiz/blink-emoji.nvim',
			'https://github.com/olimorris/codecompanion.nvim',
			'https://github.com/MeanderingProgrammer/render-markdown.nvim',
			'https://github.com/xzbdmw/colorful-menu.nvim',
		},
		event = { 'InsertEnter' },
		version = '*',
		opts = {
			keymap = {
				-- Set my own, and get rid of the ones I don't use
				preset = 'none',
				['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
				['<C-c>'] = { 'hide' },

				['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
				['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

				['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
				['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

				-- Not sure about this one 🤔
				['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
				['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
				['<Tab>'] = {
					function(cmp)
						if not has_words_before() then
							return
						end

						if cmp.is_menu_visible() then
							return cmp.select_next()
						end
					end,
					'snippet_forward',
					'fallback',
				},
				['<CR>'] = { 'select_and_accept', 'fallback' },
			},

			snippets = { preset = 'luasnip' },

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
						padding = 1,
						gap = 2,
						columns = { { 'kind_icon' }, { 'label', 'kind', gap = 2 } },
						components = {
							label = {
								width = { fill = true },
								text = function(ctx)
									return require('colorful-menu').blink_components_text(ctx)
								end,
								highlight = function(ctx)
									return require('colorful-menu').blink_components_highlight(
										ctx
									)
								end,
							},
							label_description = { width = { fill = true } },
							kind_icon = {
								text = get_icon,
								highlight = get_icon_highlight,
							},
							kind = {
								highlight = get_icon_highlight,
							},
						},
					},
				},

				documentation = {
					auto_show = true,
					treesitter_highlighting = true,
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
					treesitter_highlighting = true,
				},
			},

			cmdline = { enabled = false },

			sources = {
				default = {
					'lsp',
					'path',
					'snippets',
					'buffer',
					'emoji',
					'codecompanion',
					'markdown',
				},
				providers = {
					lsp = {
						name = 'lsp',
						enabled = true,
						module = 'blink.cmp.sources.lsp',
						-- When linking markdown notes, I would get snippets and text in the
						-- suggestions, I want those to show only if there are no LSP
						-- suggestions
						-- Disabling fallbacks as my snippets wouldn't show up
						-- Enabled fallbacks as this seems to be working now
						fallbacks = { 'buffer' },
					},
					path = {
						name = 'Path',
						module = 'blink.cmp.sources.path',
						-- When typing a path, I would get snippets and text in the
						-- suggestions, I want those to show only if there are no path
						-- suggestions
						fallbacks = { 'snippets', 'buffer' },
						opts = {
							trailing_slash = false,
							label_trailing_slash = true,
							get_cwd = function(context)
								return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
							end,
							show_hidden_files_by_default = true,
						},
					},
					buffer = {
						name = 'Buffer',
						enabled = true,
						max_items = 3,
						module = 'blink.cmp.sources.buffer',
						min_keyword_length = 4,
					},
					emoji = {
						module = 'blink-emoji',
						name = 'Emoji',
						opts = { insert = true },
					},
					snippets = {
						name = 'snippets',
						enabled = true,
						max_items = 8,
						min_keyword_length = 2,
						module = 'blink.cmp.sources.snippets',
					},
					markdown = {
						name = 'RenderMarkdown',
						module = 'render-markdown.integ.blink',
						fallbacks = { 'lsp' },
					},
				},
			},
		},
	},
}
