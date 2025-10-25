return {
	{
		'https://github.com/davidmh/mdx.nvim',
		ft = { 'mdx' },
		opts = {},
	},
	{
		'https://github.com/zk-org/zk-nvim',
		config = function()
			-- I don't need the LSP I use markdown-oxide for that, I only need the commands. This is why I don't call .setup()
			require 'zk.commands.builtin'
		end,
	},
	{
		'https://github.com/obsidian-nvim/obsidian.nvim',
		version = '*',
		cmd = { 'Obsidian' },
		ft = { 'markdown' },
		dependencies = {
			'https://github.com/nvim-lua/plenary.nvim',
		},
		opts = {
			legacy_commands = false,
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
			},

			templates = {
				folder = '.zk/templates', -- must be relative to the root of the vault
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

			frontmatter = {
				sort = { 'id', 'title', 'date', 'aliases', 'tags' },
				-- Optional, alternatively you can customize the frontmatter data.
				---@return table
				func = function(note)
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
			},

			daily_notes = {
				folder = 'journal',
				workdays_only = false,
				default_tags = { 'journal' },
				template = 'journal.md',
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

			footer = {
				enabled = false,
			},
		},
	},
}
