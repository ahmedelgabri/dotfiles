-- Markdown plugins
local pack = require 'plugins.pack'

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

-- zk-nvim: only commands, no LSP
require 'zk.commands.builtin'

local function ensure_render_markdown()
	return pack.setup('render-markdown.nvim', function()
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
	end)
end

vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'markdown', 'md', 'codecompanion' },
	callback = ensure_render_markdown,
})

local function ensure_markdown_plus()
	return pack.setup('markdown-plus.nvim', function()
		require('markdown-plus').setup {
			filetypes = { 'markdown', 'text', 'txt' },
		}
	end)
end

vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'markdown', 'txt', 'text' },
	callback = ensure_markdown_plus,
})

local obsidian_warned = false

local function notify_missing_notes_dir()
	if obsidian_warned then
		return
	end

	obsidian_warned = true
	vim.notify(
		'Obsidian disabled: NOTES_DIR is not set or does not exist',
		vim.log.levels.WARN
	)
end

local function get_notes_dir()
	local dir = vim.env.NOTES_DIR
	if dir == nil or dir == '' then
		return nil
	end

	local normalized = vim.fs.normalize(dir)
	if vim.uv.fs_stat(normalized) == nil then
		return nil
	end

	return normalized
end

local function notes_patterns(notes_dir)
	return {
		notes_dir .. '/*.md',
		notes_dir .. '/**/*.md',
		notes_dir .. '/*.markdown',
		notes_dir .. '/**/*.markdown',
	}
end

local function ensure_obsidian()
	local notes_dir = get_notes_dir()
	if notes_dir == nil then
		notify_missing_notes_dir()
		return false
	end

	return pack.setup('obsidian.nvim', function()
		require('obsidian').setup {
			legacy_commands = false,
			workspaces = {
				{
					name = 'notes',
					path = notes_dir,
					strict = true,
					overrides = {
						attachments = {
							folder = notes_dir .. '/assets',
							img_name_func = function()
								return string.format(
									'%s/%s/Pasted image %s',
									notes_dir .. '/assets',
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
					local metadata = note.metadata or {}
					local out = {
						aliases = note.aliases,
						tags = note.tags,
					}

					if not vim.tbl_isempty(metadata) then
						for k, v in pairs(metadata) do
							out[k] = v
						end
					end

					if not metadata.title then
						out.title = note.title or note.id
					end

					note:add_alias(note.title or metadata.title or note.id)

					local validated_id = convert_date(note.id)
					out.id = validated_id
						or convert_date(metadata.date or os.date '%Y%m%d%H%M')
						or os.date '%Y%m%d%H%M'

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
	end)
end

-- Lazy load on Obsidian* commands
pack.lazy_cmd('Obsidian', ensure_obsidian)

-- Also load for markdown files inside NOTES_DIR
local notes_dir = get_notes_dir()
if notes_dir ~= nil then
	vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
		pattern = notes_patterns(notes_dir),
		callback = ensure_obsidian,
	})
end
