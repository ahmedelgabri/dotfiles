local format_text = function(str)
	local n = 60
	local formatted_str = str == '' and '\n' or ''
	local len = #str
	local i = 1
	while i < len do
		local pos
		if str:sub(i + n, i + n) == ' ' then
			pos = i + n
		else
			pos = str:find(' ', i + n) or len
		end
		formatted_str = formatted_str
			.. str:sub(i, pos):gsub('^%s*(.-)%s*$', '%1')
			.. '\n'
		i = pos
	end
	return formatted_str
end

local random_quote = function()
	local quotes = require '_.quotes'
	math.randomseed(os.time())

	local quote = vim.tbl_map(format_text, quotes[math.random(#quotes)])

	local s = ''
	for _, sub in ipairs(quote) do
		s = s .. sub
	end

	return s
end

return {
	'https://github.com/folke/snacks.nvim',
	opts = {
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
				header = table.concat({
					table.concat({
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
					}, '\n'),
					'',
					vim.fn['repeat']('▁', vim.o.textwidth),
					'',
					random_quote(),
					vim.fn['repeat']('▔', vim.o.textwidth),
				}, '\n'),
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
	},
}
