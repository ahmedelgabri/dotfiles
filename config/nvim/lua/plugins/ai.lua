local utils = require '_.utils'

return {
	{
		'https://github.com/olimorris/codecompanion.nvim',
		lazy = false,
		version = 'v17.33.0',
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
			vim.cmd.cabbrev { 'cc', 'CodeCompanion' }
		end,
		opts = function(_, opts)
			local adapter = 'claude_code'

			return vim.tbl_deep_extend('force', opts or {}, {
				opts = {
					visible = true,
					language = "the same language of user's question",
					log_level = 'TRACE', -- TRACE|DEBUG|ERROR|INFO
				},
				memory = {
					opts = {
						chat = {
							enabled = true,
						},
					},
				},
				adapters = {
					acp = {
						claude_code = function()
							return require('codecompanion.adapters').extend('claude_code', {
								commands = {
									default = {
										'bunx',
										'--silent',
										'@zed-industries/claude-code-acp',
									},
								},
								env = {
									-- https://codecompanion.olimorris.dev/configuration/adapters#using-claude-pro-subscription
									CLAUDE_CODE_OAUTH_TOKEN = 'cmd:pass show secret/claude_oauth_token',
								},
							})
						end,
						gemini_cli = function()
							return require('codecompanion.adapters').extend('gemini_cli', {
								commands = {
									default = {
										'gemini',
										'--experimental-acp',
										'-m',
										'gemini-2.5-flash',
									},
									flash = {
										'gemini',
										'--experimental-acp',
										'-m',
										'gemini-2.5-flash',
									},
									pro = {
										'gemini',
										'--experimental-acp',
										'-m',
										'gemini-2.5-pro',
									},
								},
								defaults = {
									auth_method = utils.is_rocket() and 'oauth-personal'
										or 'gemini-api-key',
								},
							})
						end,
					},
					http = {
						llamacpp = function()
							return require('codecompanion.adapters').extend(
								'openai_compatible',
								{
									name = 'llamacpp',
									formatted_name = 'Llamacpp',
									schema = {
										model = {
											default = 'unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF',
										},
									},
									env = {
										url = 'http://localhost:8080',
										api_key = 'TERM',
									},
									handlers = {
										inline_output = function(self, data)
											local openai = require 'codecompanion.adapters.openai'
											return openai.handlers.inline_output(self, data)
										end,
										chat_output = function(self, data)
											local openai = require 'codecompanion.adapters.openai'
											local result = openai.handlers.chat_output(self, data)
											if result ~= nil then
												result.output.role = 'assistant'
											end
											return result
										end,
									},
								}
							)
						end,
					},
				},
				-- prompt_library = {},
				strategies = {
					chat = {
						adapter = adapter,
						roles = {
							llm = function(adp)
								local icon = require('mini.icons').get('filetype', adp.name)

								return string.format(
									' %s %s (%s)',
									icon .. ' ',
									adp.name,
									adp.type == 'acp' and adp.formatted_name or adp.model.name
								)
							end,
							user = vim.env.USER,
						},
						slash_commands = {
							buffer = {
								opts = {
									provider = 'default',
								},
							},
							file = {
								opts = {
									provider = 'default',
								},
							},
							help = {
								opts = {
									provider = 'default',
								},
							},
						},
					},
					cmd = { adapter = adapter },
					inline = { adapter = adapter },
					agent = {
						adapter = adapter,
					},
				},
				display = {
					chat = {
						intro_message = 'Press ? for options',
						show_setting = true,
						show_token_count = true,
						token_count = function(tokens, _adp)
							return ' (' .. tokens .. ' tokens) '
						end,
						window = {
							position = 'right',
						},
					},
					diff = {
						provider = 'mini_diff',
					},
				},
			})
		end,
	},
	-- TODO: Change keymaps for LSP to start with <leader>l to avoid conflicts
	{
		'https://github.com/folke/sidekick.nvim',
		opts = {
			mux = { enabled = true },
		},
		keys = {
			{
				'<c-.>',
				function()
					require('sidekick.cli').toggle()
				end,
				desc = 'Sidekick Toggle',
				mode = { 'n', 't', 'i', 'x' },
			},
			{
				'<localleader>aa',
				function()
					require('sidekick.cli').toggle()
				end,
				desc = 'Sidekick Toggle CLI',
			},
			{
				'<localleader>as',
				function()
					require('sidekick.cli').select { filter = { installed = true } }
				end,
				desc = 'Select CLI',
			},
			{
				'<localleader>at',
				function()
					require('sidekick.cli').send { msg = '{this}' }
				end,
				mode = { 'x', 'n' },
				desc = 'Send This',
			},
			{
				'<localleader>af',
				function()
					require('sidekick.cli').send { msg = '{file}' }
				end,
				desc = 'Send File',
			},
			{
				'<localleader>av',
				function()
					require('sidekick.cli').send { msg = '{selection}' }
				end,
				mode = { 'x' },
				desc = 'Send Visual Selection',
			},
			{
				'<localleader>ap',
				function()
					require('sidekick.cli').prompt()
				end,
				mode = { 'n', 'x' },
				desc = 'Sidekick Select Prompt',
			},
		},
	},
}
