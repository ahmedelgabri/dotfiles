local au = require '_.utils.au'
local utils = require '_.utils'

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

return {
	'https://github.com/folke/snacks.nvim',
	event = { 'UIEnter' },
	keys = {
		{
			'<leader>.',
			function()
				vim.ui.input({
					prompt = 'Enter filetype for the scratch buffer: ',
					default = 'markdown',
					completion = 'filetype',
				}, function(ft)
					local snacks = require 'snacks'

					snacks.scratch.open {
						ft = ft,
						win = {
							width = 150,
							height = 40,
							border = utils.get_border(),
							title = 'Scratch Buffer',
						},
					}
				end)
			end,
			{ desc = 'Toggle Scratch Buffer' },
		},
		{
			'<leader>S',
			function()
				local snacks = require 'snacks'

				snacks.scratch.select()
			end,
			{ desc = 'Select Scratch Buffer' },
		},
	},
	init = function()
		vim.api.nvim_create_autocmd('User', {
			pattern = 'VeryLazy',
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command

				-- Create some toggle mappings
				Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
				Snacks.toggle.diagnostics():map '<leader>ud'
				Snacks.toggle.inlay_hints():map '<leader>uh'
				Snacks.toggle.dim():map '<leader>uD'
			end,
		})
		-- disable in some buffers
		au.autocmd {
			event = { 'FileType' },
			pattern = {
				'fzf',
				'startify',
				'ministarter',
				'snacks_dashboard',
				'help',
				'alpha',
				'dashboard',
				'neo-tree',
				'Trouble',
				'lazy',
				'grug-far',
				'mason',
			},
			callback = function()
				vim.b.snacks_indent = true
			end,
		}
	end,
	opts = {
		quickfile = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },

		bigfile = {
			enabled = true,
			size = 1024 * 500, -- 500KB
		},
		notifier = { enabled = true },
		debug = { enabled = true },
		indent = {
			animate = {
				enabled = false,
			},
			indent = {
				char = '┆', -- alts: ┊│┆ ┊  ▎││ ▏▏
				only_scope = true,
			},
			chunk = {
				enabled = true,
				char = {
					corner_top = '┏',
					corner_bottom = '┗',
					horizontal = '━',
					vertical = '┃',
					arrow = '>',
				},
			},
		},
		input = {
			win = {
				style = {
					border = utils.get_border(),
					relative = 'cursor',
					width = 45,
					row = -3,
					col = 0,
					wo = {
						winhighlight = 'NormalFloat:SnacksInputNormal,FloatBorder:Comment,FloatTitle:Normal',
					},
				},
			},
		},
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
	},
}
