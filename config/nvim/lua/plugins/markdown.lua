return {
	{
		'https://github.com/iamcco/markdown-preview.nvim',
		cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
		ft = { 'markdown' },
		keys = {
			{
				'<leader>p',
				vim.cmd.MarkdownPreview,
				noremap = true,
				buffer = true,
				desc = '[P]review Markdown',
			},
		},
		build = function()
			require('lazy').load { plugins = { 'markdown-preview.nvim' } }
			vim.fn['mkdp#util#install']()
		end,
	},
	{
		'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		ft = { 'markdown', 'codecompanion', 'gitcommit' },
		opts = function(_, opts)
			return vim.tbl_deep_extend('force', opts or {}, {
				completions = {
					lsp = {
						enabled = true,
					},
				},
				render_modes = { 'n', 'c', 'i', 'v', 'V', '\22', 't' },
				-- anti_conceal = { enabled = false },
				sign = { enabled = false },
				indent = { enabled = false },
				dash = { icon = '🬋' },
				heading = { position = 'inline' },
				code = {
					position = 'right',
					width = 'block',
					min_width = 45,
					border = 'thick',
					left_pad = 2,
					right_pad = 2,
				},
				link = {
					custom = {
						github = {
							pattern = '^http[s]?://w*%.?github%.com/.*',
							icon = require('mini.icons').get('directory', '.github') .. ' ',
							highlight = 'RenderMarkdownGithubLink',
						},
						file = {
							pattern = '^file:',
							icon = "'",
							highlight = 'RenderMarkdownFileLink',
						},
						youtube = {
							pattern = '^http[s]?://www%.youtube%.com/.*',
							icon = "'",
							highlight = 'RenderMarkdownYoutubeLink',
						},
					},
				},
				pipe_table = {
					preset = 'heavy',
					cell = 'trimmed',
				},
				checkbox = {
					-- position = 'overlay',
					checked = { scope_highlight = '@markup.strikethrough' },
				},
				overrides = {
					filetype = {
						gitcommit = { heading = { enabled = false } },
					},
				},
				injections = {
					gitcommit = {
						enabled = true,
						query = [[
                ((message) @injection.content
                    (#set! injection.combined)
                    (#set! injection.include-children)
                    (#set! injection.language "markdown"))
            ]],
					},
				},
			})
		end,
	},
	{
		'https://github.com/davidmh/mdx.nvim',
		ft = { 'mdx' },
		opts = {},
	},
	{
		'https://github.com/zk-org/zk-nvim',
		config = function()
			require('zk').setup {
				picker = 'fzf_lua',
			}
		end,
	},
	{
		'https://github.com/obsidian-nvim/obsidian.nvim',
		version = '*', -- recommended, use latest release instead of latest commit
		cmd = { 'Obsidian' },
		ft = { 'markdown' },
		dependencies = {
			'https://github.com/nvim-lua/plenary.nvim',
		},
		opts = {
			workspaces = {
				{
					name = 'notes',
					path = vim.env.NOTES_DIR,
					strict = true,
					overrides = {
						attachments = {
							img_folder = vim.env.NOTES_DIR .. '/assets',
							img_name_func = function()
								return string.format(
									'%s/%s/Pasted image %s',
									vim.env.NOTES_DIR .. '/assets',
									vim.fn.expand '%:t:r',
									os.date '%Y%m%d%H%M%S'
								)
							end,
						},
					},
				},
				{
					name = 'no-vault',
					path = function()
						-- alternatively use the CWD:
						-- return assert(vim.fn.getcwd())
						return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
					end,
					overrides = {
						disable_frontmatter = true,
						notes_subdir = vim.NIL, -- have to use 'vim.NIL' instead of 'nil'
						new_notes_location = 'current_dir',
						templates = {
							folder = vim.NIL,
						},
						attachments = {
							img_folder = 'assets',
						},
					},
				},
			},

			templates = {
				folder = vim.fn.expand '~/.config/zk/templates',
				date_format = '%Y-%m-%d',
				time_format = '%H:%M',
				-- A map for custom variables, the key should be the variable and the value a function
				substitutions = {
					-- zk compatibility
					-- https://zk-org.github.io/zk/notes/template.html#date-formatting-helper
					['format-date now "%Y-%m-%dT%H:%M"'] = function()
						return os.date '%Y-%m-%dT%H:%M' -- 2025-04-01T12:05
					end,
					['format-date now "timestamp"'] = function()
						return os.date '%Y%m%d%H%M' -- 202504011205
					end,
					["format-date now '%Y-%m-%d'"] = function()
						return os.date '%Y-%m-%d' -- 2025-04-01
					end,
					['format-date now "long"'] = function()
						return os.date '%B %d, %Y' -- April 1, 2025
					end,
					['content'] = function()
						return ''
					end,
					['extra.employer'] = function()
						return vim.env.COMPANY or 'NO COMPANY'
					end,
				},
			},

			---@param title string|?
			---@return string
			note_id_func = function(title)
				local note_name = tostring(os.date '%Y%m%d%H%M')

				if title ~= nil then
					note_name = note_name
						.. ' '
						.. title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
				end

				return note_name
			end,

			-- Optional, alternatively you can customize the frontmatter data.
			---@return table
			note_frontmatter_func = function(note)
				local function convert_date(date_string)
					local year, month, day, hour, min

					-- Try to match date with time
					year, month, day, hour, min =
						date_string:match '(%d+)-(%d+)-(%d+)[T ](%d+):(%d+)'

					if not year then
						-- Try to match date only
						year, month, day = date_string:match '(%d+)-(%d+)-(%d+)'
						hour, min = 0, 0
					end

					if year then
						-- Create date table for os.time
						local date_table = {
							year = tonumber(year),
							month = tonumber(month),
							day = tonumber(day),
							hour = tonumber(hour) or 0,
							min = tonumber(min) or 0,
							sec = 0,
						}

						-- Convert to timestamp
						local timestamp = os.time(date_table)

						-- Format using os.date
						return os.date('%Y%m%d%H%M', timestamp)
					else
						return nil, 'Invalid date format'
					end
				end

				-- Add the title of the note as an alias.
				if note.title then
					note:add_alias(note.title)
				end

				local out = {
					aliases = note.aliases,
					tags = note.tags,
				}

				-- `note.metadata` contains any manually added fields in the frontmatter.
				-- So here we just make sure those fields are kept in the frontmatter.
				if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
					for k, v in pairs(note.metadata) do
						out[k] = v
					end
				end

				-- We run this at the end so we have access to metadata too
				out.id = note.id
					or tostring(convert_date(note.metadata.date))
					or tostring(os.date '%Y%m%d%H%M')

				return out
			end,

			daily_notes = {
				folder = 'journal',
				workdays_only = false,
				default_tags = { 'journal' },
				template = vim.fn.expand '~/.config/zk/templates/journal.md',
			},

			completion = {
				nvim_cmp = false,
				blink = false,
			},

			ui = {
				enable = false,
			},

			attachments = {
				img_folder = 'assets',
			},

			open = {
				func = function(uri)
					vim.ui.open(
						uri,
						{ cmd = { 'open', '-a', '/Applications/Obsidian.app' } }
					)
				end,
			},
		},
	},
}
