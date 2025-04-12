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
				opts = {
					visible = true,
					language = "the same language of user's question",
					log_level = 'TRACE', -- TRACE|DEBUG|ERROR|INFO
				},
				adapters = {
					gemini = function()
						return require('codecompanion.adapters').extend('gemini', {
							schema = {
								model = {
									default = 'gemini-2.5-pro-exp-03-25',
								},
							},
						})
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
				prompt_library = {
					['Generate a Commit Message'] = {
						opts = {
							adapter = {
								name = adapter,
								model = adapter == 'anthropic' and 'claude-3-5-sonnet-20241022'
									or nil,
							},
						},
					},
				},
				strategies = {
					chat = {
						adapter = adapter,
						roles = {
							llm = function(adp)
								local icon = require('mini.icons').get(
									'lsp',
									adp.name == 'anthropic' and 'claude' or adp.name
								)

								return string.format(
									' %s %s (%s)',
									icon .. ' ',
									adp.name,
									adp.schema.model.default
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
						adapter = adapter == 'copilot' and 'copilot' or 'anthropic',
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
						show_header_separator = true,
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
			copilot_node_command = vim.fn.expand '~/.volta/bin/node',
			server = {
				type = 'binary',
				custom_server_filepath = 'copilot-language-server',
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
