return {
	'https://github.com/folke/snacks.nvim',
	config = function()
		local top_header = table.concat({
			-- https://github.com/NvChad/NvChad/discussions/2755#discussioncomment-8960250
			'           ▄ ▄                   ',
			'       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ',
			'       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ',
			'    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ',
			'  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ',
			'  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄',
			'▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █',
			'█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █',
			'    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ',
		}, '\n')

		local sep = vim.fn['repeat']('▁', vim.o.textwidth)

		local function wrap_text(input_table, width)
			local wrapped_lines = {}

			for _, line in ipairs(input_table) do
				if line == '' then
					-- Retain empty strings as line breaks
					table.insert(wrapped_lines, '')
				else
					local line_start = 1
					while line_start <= #line do
						-- Determine the end of the current segment
						local line_end = math.min(line_start + width - 1, #line)

						-- Adjust to break at the last space within the width limit
						if line_end < #line then
							local space_pos = line:sub(line_start, line_end):find ' [^ ]*$'
							if space_pos then
								line_end = line_start + space_pos - 1
							end
						end

						-- Extract the substring and ensure it's valid
						local segment = line:sub(line_start, line_end):gsub('^%s*', '')
						if segment ~= '' then
							table.insert(wrapped_lines, segment)
						end

						line_start = line_end + 1
					end
				end
			end

			return table.concat(wrapped_lines, '\n')
		end

		local random_quote = function()
			local quotes = require '_.quotes'
			math.randomseed(os.time())

			return quotes[math.random(#quotes)]
		end

		local header = table.concat({
			top_header,
			'',
			sep,
			'',
			wrap_text(random_quote(), 60),
			sep,
		}, '\n')

		require('snacks').setup {
			notifier = { enabled = true },
			debug = { enabled = true },
			bigfile = { size = 1024 * 500 }, -- 500KB
			dashboard = {
				preset = {
					keys = {
						{
							key = 'e',
							desc = 'New File',
							action = ':ene',
						},
						{
							desc = 'Sync',
							action = ':Lazy sync',
							key = 's',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Update',
							action = ':Lazy update',
							key = 'u',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Clean',
							action = ':Lazy clean',
							key = 'c',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Profile',
							action = ':Lazy profile',
							key = 'p',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Git Todo',
							action = ':e .git/todo.md',
							key = 't',
						},
						{ key = 'q', desc = 'Quit', action = ':qa' },
					},
					header = header,
				},
				formats = {
					key = function(item)
						return {
							{ '[', hl = 'special' },
							{ item.key, hl = 'key' },
							{ ']', hl = 'special' },
						}
					end,
				},
				sections = {
					{ section = 'header' },
					{ title = 'MRU', padding = 1 },
					{ section = 'recent_files', limit = 8, padding = 1 },
					{ title = 'MRU ', file = vim.fn.fnamemodify('.', ':~'), padding = 1 },
					{ section = 'recent_files', cwd = true, limit = 8, padding = 1 },
					{ title = 'Sessions', padding = 1 },
					{ section = 'projects', padding = 1 },
					{ title = 'Bookmarks', padding = 1 },
					{ section = 'keys' },
					{ section = 'startup' },
				},
			},
		}
	end,
}
