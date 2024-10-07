local utils = require '_.utils'
local adapter = utils.is_rocket() and 'copilot' or 'anthropic'

return {
	{
		'https://github.com/olimorris/codecompanion.nvim',
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
		config = function()
			local icon = adapter == 'copilot'
					and require('mini.icons').get('directory', '.github')
				or require('mini.icons').get('lsp', 'codecompanion')

			require('codecompanion').setup {
				strategies = {
					chat = {
						adapter = adapter,
						roles = {
							llm = icon .. ' ',
							user = vim.env.USER,
						},
						slash_commands = {
							['buffer'] = {
								opts = {
									provider = 'fzf_lua',
								},
							},
							['file'] = {
								opts = {
									provider = 'fzf_lua',
								},
							},
							['help'] = {
								opts = {
									provider = 'fzf_lua',
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
					diff = {
						provider = 'mini_diff',
					},
				},
				-- opts = {
				-- 	log_level = 'DEBUG',
				-- },
			}
		end,
	},
	{
		'https://github.com/zbirenbaum/copilot.lua',
		dependencies = {
			'https://github.com/zbirenbaum/copilot-cmp',
			opts = {},
		},
		enabled = utils.is_rocket(),
		build = ':Copilot auth',
		event = 'InsertEnter',
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = {
				yaml = true,
				markdown = true,
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
	-- 		condition = function()
	-- 			local match = vim.bo.filetype == ''
	-- 				or vim.fn.expand '%:t:r' == '.envrc'
	-- 				or vim.fn.expand '%:t:r' == '.env'
	-- 				or vim.tbl_contains(
	-- 					{ vim.fn.expand '$HOST_CONFIGS/zshrc' },
	-- 					vim.fn.expand '%'
	-- 				)
	--
	-- 			return match
	-- 		end,
	-- 		disable_inline_completion = false, -- disables inline completion for use with cmp
	-- 		disable_keymaps = false, -- disables built in keymaps for more manual control
	-- 	},
	-- },
}
