-- Markdown plugins

-- Pattern definitions for obsidian date parsing
local patterns = {
	{
		name = 'ISO datetime',
		pattern = '^(%d%d%d%d)-(%d%d)-(%d%d)[T ](%d%d):(%d%d)',
		defaults = {},
	},
	{
		name = 'compact datetime',
		pattern = '^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)$',
		defaults = {},
	},
	{
		name = 'ISO date',
		pattern = '^(%d%d%d%d)-(%d%d)-(%d%d)$',
		defaults = { hour = 0, min = 0 },
	},
}

local function convert_date(date_string)
	local year, month, day, hour, min

	for _, config in ipairs(patterns) do
		local captures = { date_string:match(config.pattern) }
		if #captures > 0 then
			year, month, day = captures[1], captures[2], captures[3]
			hour = captures[4] or config.defaults.hour
			min = captures[5] or config.defaults.min
			break
		end
	end

	if not year then
		return nil
	end

	local date_table = {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour) or 0,
		min = tonumber(min) or 0,
		sec = 0,
	}

	local timestamp = os.time(date_table)
	return os.date('%Y%m%d%H%M', timestamp)
end

-- Eager markdown plugins
vim.pack.add {
	'https://github.com/MeanderingProgrammer/render-markdown.nvim',
	'https://github.com/davidmh/mdx.nvim',
	'https://github.com/zk-org/zk-nvim',
}

-- render-markdown setup
require('render-markdown').setup {
	file_types = { 'markdown', 'md', 'codecompanion' },
	render_modes = { 'n', 'no', 'c', 't', 'i', 'ic' },
	code = {
		sign = false,
		border = 'thin',
		position = 'right',
		width = 'block',
		above = '▁',
		below = '▔',
		language_left = '█',
		language_right = '█',
		language_border = '▁',
		left_pad = 1,
		right_pad = 1,
	},
	heading = {
		sign = false,
		width = 'block',
		left_pad = 1,
		right_pad = 0,
		position = 'inline',
		icons = { '󰉫  ', '󰉬  ', '󰉭  ', '󰉮  ', '󰉯  ', '󰉰  ' },
	},
}

-- zk-nvim: only commands, no LSP
require 'zk.commands.builtin'

-- markdown-plus: lazy on filetype
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'markdown', 'txt', 'text' },
	once = true,
	callback = function()
		vim.pack.add { 'https://github.com/YousefHadder/markdown-plus.nvim' }
		require('markdown-plus').setup {
			filetypes = { 'markdown', 'text', 'txt' },
		}
	end,
})

-- obsidian.nvim: lazy on cmd and filetype
do
	local obsidian_loaded = false
	local function ensure_obsidian()
		if obsidian_loaded then
			return
		end
		obsidian_loaded = true
		vim.pack.add {
			'https://github.com/nvim-lua/plenary.nvim',
			{
				src = 'https://github.com/obsidian-nvim/obsidian.nvim',
				version = vim.version.range '*',
			},
		}

		require('obsidian').setup {
			legacy_commands = false,
			workspaces = {
				{
					name = 'notes',
					path = vim.env.NOTES_DIR,
					strict = true,
					overrides = {
						attachments = {
							folder = vim.env.NOTES_DIR .. '/assets',
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
				folder = '.zk/templates',
				date_format = '%Y-%m-%d',
				time_format = '%H:%M',
				substitutions = {
					['format-date now "%Y-%m-%dT%H:%M"'] = function()
						return os.date '%Y-%m-%dT%H:%M'
					end,
					['format-date now "timestamp"'] = function()
						return os.date '%Y%m%d%H%M'
					end,
					["format-date now '%Y-%m-%d'"] = function()
						return os.date '%Y-%m-%d'
					end,
					['format-date now "long"'] = function()
						return os.date '%B %d, %Y'
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
				---@return table
				func = function(note)
					local out = {
						aliases = note.aliases,
						tags = note.tags,
					}

					if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
						for k, v in pairs(note.metadata) do
							out[k] = v
						end
					end

					if not note.metadata.title then
						out.title = note.title or note.id
					end

					note:add_alias(note.title or note.metadata.title or note.id)

					local validated_id = tostring(convert_date(note.id))
					out.id = validated_id ~= 'nil' and validated_id
						or tostring(
							convert_date(note.metadata.date or os.date '%Y%m%d%H%M')
						)

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
				folder = 'assets',
			},

			footer = {
				enabled = false,
			},
		}
	end

	-- Lazy load on Obsidian* commands
	vim.api.nvim_create_user_command('Obsidian', function(opts)
		pcall(vim.api.nvim_del_user_command, 'Obsidian')
		ensure_obsidian()
		vim.cmd('Obsidian ' .. (opts.args or ''))
	end, { nargs = '*' })

	-- Also load on markdown filetype
	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'markdown',
		once = true,
		callback = ensure_obsidian,
	})
end
