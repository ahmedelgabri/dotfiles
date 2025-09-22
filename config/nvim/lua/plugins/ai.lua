local utils = require '_.utils'

return {
	{
		'https://github.com/olimorris/codecompanion.nvim',
		lazy = false,
		dependencies = {
			'https://github.com/ravitemer/codecompanion-history.nvim',
		},
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
			local adapter = utils.is_rocket() and 'gemini_cli' or 'claude_code'

			return vim.tbl_deep_extend('force', opts or {}, {
				opts = {
					visible = true,
					language = "the same language of user's question",
					log_level = 'TRACE', -- TRACE|DEBUG|ERROR|INFO
				},
				extensions = {
					history = {
						enabled = true,
						opts = {
							dir_to_save = vim.env.XDG_CONFIG_HOME .. '/codecompanion-history',
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
									ANTHROPIC_API_KEY = vim.env.ANTHROPIC_API_KEY,
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
						swama = function()
							return require('codecompanion.adapters').extend(
								'openai_compatible',
								{
									env = {
										url = 'http://localhost:28100',
									},
									schema = {
										model = {
											default = 'mlx-community/Qwen3-32B-4bit',
										},
										temperature = {
											order = 2,
											mapping = 'parameters',
											type = 'number',
											optional = true,
											default = 0.8,
											desc = 'What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both.',
											validate = function(n)
												return n >= 0 and n <= 2, 'Must be between 0 and 2'
											end,
										},
										max_completion_tokens = {
											order = 3,
											mapping = 'parameters',
											type = 'integer',
											optional = true,
											default = nil,
											desc = 'An upper bound for the number of tokens that can be generated for a completion.',
											validate = function(n)
												return n > 0, 'Must be greater than 0'
											end,
										},
										stop = {
											order = 4,
											mapping = 'parameters',
											type = 'string',
											optional = true,
											default = nil,
											desc = 'Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate stop parameters in a modelfile.',
											validate = function(s)
												return s:len() > 0, 'Cannot be an empty string'
											end,
										},
										logit_bias = {
											order = 5,
											mapping = 'parameters',
											type = 'map',
											optional = true,
											default = nil,
											desc = 'Modify the likelihood of specified tokens appearing in the completion. Maps tokens (specified by their token ID) to an associated bias value from -100 to 100. Use https://platform.openai.com/tokenizer to find token IDs.',
											subtype_key = {
												type = 'integer',
											},
											subtype = {
												type = 'integer',
												validate = function(n)
													return n >= -100 and n <= 100,
														'Must be between -100 and 100'
												end,
											},
										},
									},
								}
							)
						end,
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
						openrouter = function()
							return require('codecompanion.adapters').extend(
								'openai_compatible',
								{
									env = {
										api_key = vim.env.OPENROUTER_API_KEY,
									},
									url = 'https://openrouter.ai/api/v1/chat/completions',
									schema = {
										temperature = {
											default = 0.6,
										},
										model = {
											default = 'deepseek/deepseek-chat-v3-0324:free',
											choices = {
												'deepseek/deepseek-r1-zero:free',
												'deepseek/deepseek-chat-v3-0324:free',
											},
										},
										num_ctx = {
											default = 200000,
										},
									},
								}
							)
						end,
						-- https://github.com/olimorris/codecompanion.nvim/discussions/263#discussioncomment-10793002
						groq = function()
							return require('codecompanion.adapters').extend('openai', {
								env = {
									api_key = vim.env.GROQ_API_KEY,
								},
								name = 'Groq',
								url = 'https://api.groq.com/openai/v1/chat/completions',
								schema = {
									model = {
										default = 'deepseek-r1-distill-llama-70b',
										choices = {
											'deepseek-r1-distill-llama-70b',
											'meta-llama/llama-4-maverick-17b-128e-instruct',
										},
									},
								},
								max_tokens = {
									default = 8192,
								},
								temperature = {
									default = 1,
								},
								handlers = {
									form_messages = function(_, messages)
										for _, msg in ipairs(messages) do
											-- Remove 'id' and 'opts' properties from all messages
											msg.id = nil
											msg.opts = nil

											-- Ensure 'name' is a string if present, otherwise remove it
											if msg.name then
												msg.name = tostring(msg.name)
											else
												msg.name = nil
											end

											-- Ensure only supported properties are present
											local supported_props =
												{ role = true, content = true, name = true }
											for prop in pairs(msg) do
												if not supported_props[prop] then
													msg[prop] = nil
												end
											end
										end
										return { messages = messages }
									end,
								},
							})
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
	{
		'https://github.com/zbirenbaum/copilot.lua',
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
			copilot_node_command = vim.fn.expand '~/.local/share/mise/installs/node/latest/bin/node',
			server = {
				type = 'binary',
				custom_server_filepath = vim.fn.exepath 'copilot-language-server',
			},
		},
	},
}
