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
		dependencies = {
			-- "https://github.com/nvim-lua/plenary.nvim",
			-- "nvim-treesitter/nvim-treesitter",
			-- "hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
			-- "nvim-telescope/telescope.nvim", -- Optional: For using slash commands
			-- { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
		},
		opts = {
			strategies = {
				chat = {
					adapter = adapter,
					roles = {
						-- llm = 'CodeCompanion', -- The markdown header content for the LLM's responses
						user = vim.env.USER,
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
		},
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
