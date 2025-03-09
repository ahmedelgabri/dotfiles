local utils = require '_.utils'

return {
	{
		'https://github.com/olimorris/codecompanion.nvim',
		lazy = false,
		keys = {
			{
				'<localleader>ca',
				'<cmd>CodeCompanionActions<cr>',
				mode = { 'n', 'v' },
			},
			{
				'<LocalLeader>cc',
				'<cmd>CodeCompanionChat Toggle<cr>',
				mode = { 'n', 'v' },
			},
			{ '<localleader>cd', '<cmd>CodeCompanionChat Add<cr>', mode = { 'v' } },
		},
		init = function()
			vim.cmd [[cab cc CodeCompanion]]
		end,
		opts = function(_, opts)
			local adapter = utils.is_rocket() and 'copilot' or 'anthropic'

			return vim.tbl_deep_extend('force', opts or {}, {
				adapters = {
					anthropic = function()
						return require('codecompanion.adapters').extend('anthropic', {
							schema = {
								model = {
									default = 'claude-3-5-sonnet-20241022',
								},
							},
						})
					end,
				},
				strategies = {
					chat = {
						adapter = adapter,
						roles = {
							---The header name for the LLM's messages
							---@type string|fun(a: CodeCompanion.Adapter): string
							llm = function(a)
								local icon = require('mini.icons').get(
									'lsp',
									a.name == 'anthropic' and 'claude' or a.name
								)

								return string.format(
									' %s %s (%s)',
									icon,
									a.formatted_name,
									a.schema.model.default
								)
							end,
							user = vim.env.USER,
						},
						slash_commands = {
							buffer = {
								opts = {
									provider = 'snacks',
								},
							},
							file = {
								opts = {
									provider = 'snacks',
								},
							},
							help = {
								opts = {
									provider = 'snacks',
								},
							},
						},
					},
					inline = {
						adapter = adapter,
					},
					agent = {
						adapter = adapter,
					},
				},
				display = {
					chat = {
						show_header_separator = true,
						window = {
							position = 'right',
						},
					},
					diff = {
						provider = 'mini_diff',
					},
				},
				-- opts = {
				-- 	log_level = 'DEBUG',
				-- },
			})
		end,
	},
	{
		'https://github.com/zbirenbaum/copilot.lua',
		dependacies = {
			'https://github.com/giuxtaposition/blink-cmp-copilot',
		},
		enabled = utils.is_rocket(),
		build = ':Copilot auth',
		event = 'InsertEnter',
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = {
				['*'] = function()
					if
						string.match(
							vim.fs.basename(vim.api.nvim_buf_get_name(0)),
							'^%.env.*'
						)
					then
						-- disable for .env files
						return false
					end
					return true
				end,
			},
			copilot_node_command = vim.fn.expand '~/.volta/bin/node',
		},
	},
	-- https://github.com/supermaven-inc/supermaven-nvim/issues/85
	-- {
	-- 	'https://github.com/supermaven-inc/supermaven-nvim',
	-- 	enabled = not utils.is_rocket(),
	-- 	event = 'InsertEnter',
	-- 	opts = {
	-- 		keymaps = {
	-- 			accept_suggestion = '<C-g>',
	-- 			ignore_filetypes = {
	-- 				ministarter = true,
	-- 				dotenv = true,
	-- 				['grug-far'] = true,
	-- 				['grug-far-history'] = true,
	-- 				['grug-far-help'] = true,
	-- 			},
	-- 			-- clear_suggestion = '<C-]>',
	-- 			-- accept_word = '<C-j>',
	-- 		},
	-- 		-- Disable supermaven on condition https://github.com/supermaven-inc/supermaven-nvim/pull/58
	-- 		condition = function()
	-- 			local match = vim.bo.filetype == ''
	-- 				-- Disable on .env files
	-- 				or (vim.fn.expand '%:t:r'):match '^.env.*' ~= nil
	-- 				-- Disable on ZSH shell files
	-- 				or (vim.fn.expand '%:t'):match '^.?zsh.*' ~= nil
	-- 				-- Disable on all shell files
	-- 				or vim.tbl_contains({
	-- 					'sh',
	-- 					'bash',
	-- 					'zsh',
	-- 				}, vim.bo.filetype)
	--
	-- 			return match
	-- 		end,
	-- 		disable_inline_completion = false, -- disables inline completion for use with cmp
	-- 		disable_keymaps = false, -- disables built in keymaps for more manual control
	-- 	},
	-- },
}
