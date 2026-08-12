-- Completion and snippets
local pack = require '_.pack'

local utils = require '_.utils'

pack.add {
	{ src = 'https://github.com/rafamadriz/friendly-snippets', load = false },
	{
		src = 'https://github.com/L3MON4D3/LuaSnip',
		event = { 'InsertEnter' },
		load = false,
		config = function()
			vim.cmd.packadd 'friendly-snippets'

			-- Setup toggle choice
			vim.keymap.set({ 'i', 's' }, '<C-l>', function()
				local ok, ls = pcall(require, 'luasnip')
				if ok and ls.choice_active() then
					ls.change_choice(1)
				end
			end, { silent = true })

			local ls = require 'luasnip'

			local types = require 'luasnip.util.types'

			ls.config.set_config {
				history = true,
				enable_autosnippets = true,
				store_selection_keys = '<Tab>', -- needed for TM_SELECTED_TEXT
				updateevents = 'TextChanged,TextChangedI', -- default is InsertLeave
				ext_opts = {
					[types.choiceNode] = {
						active = {
							virt_text = { { '← Choice', 'Todo' } },
						},
					},
				},
			}

			require('luasnip.loaders.from_vscode').lazy_load {
				lazy_paths = {
					-- $HOST_CONFIGS is ~/.local/share/<host> keyed by the logical
					-- host name; vim.fn.hostname() is only a fallback because the
					-- MDM owns the machine name on work hosts.
					string.format(
						'%s/snippets',
						vim.env.HOST_CONFIGS
							or string.format(
								'%s/%s',
								vim.env.XDG_DATA_HOME,
								vim.fn.hostname()
							)
					),
				},
			}

			require('_.snippets').setup()
		end,
		build = function(plugin)
			vim.fn.system { 'make', '-C', plugin.path, 'install_jsregexp' }
		end,
	},
	{ src = 'https://github.com/moyiz/blink-emoji.nvim', load = false },
	{ src = 'https://github.com/xzbdmw/colorful-menu.nvim', load = false },
	{ src = 'https://github.com/Saghen/blink.lib', load = false },
	{
		src = 'https://github.com/Saghen/blink.cmp',
		name = 'blink.cmp',
		version = 'main',
		event = { 'InsertEnter' },
		config = function()
			vim.cmd.packadd 'blink.lib'
			vim.cmd.packadd 'blink-emoji.nvim'
			vim.cmd.packadd 'colorful-menu.nvim'

			local has_words_before = function()
				if
					vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'prompt'
				then
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

			require('blink.cmp').setup {
				keymap = {
					-- Set my own, and get rid of the ones I don't use
					preset = 'none',
					['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
					['<C-c>'] = { 'hide' },

					['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
					['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

					['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
					['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

					-- Not sure about this one
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

				fuzzy = {
					implementation = 'prefer_rust',
				},

				completion = {
					accept = {
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
									-- Don't fill: only `label` should absorb slack so `kind`
									-- stays right-aligned in a fixed column.
									width = { fill = false },
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
					},
					providers = {
						lsp = {
							name = 'lsp',
							enabled = true,
							module = 'blink.cmp.sources.lsp',
							fallbacks = { 'buffer' },
						},
						path = {
							name = 'Path',
							module = 'blink.cmp.sources.path',
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
					},
				},
			}
		end,
		build = function()
			vim.cmd.packadd 'blink.lib'

			local ok, err = pcall(function()
				local download = require('blink.cmp').download
				download({ force = true, match = '*' }):wait(60000)
			end)
			if not ok then
				vim.notify(err, vim.log.levels.WARN, { title = 'blink.cmp binary' })
			end
		end,
	},
}
