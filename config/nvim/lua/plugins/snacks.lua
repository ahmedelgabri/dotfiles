---@diagnostic disable: missing-fields
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
	priority = 1000,
	lazy = false,
	keys = {
		{
			'<leader>.',
			function()
				vim.ui.input({
					prompt = 'Enter filetype for the scratch buffer: ',
					default = 'markdown',
					completion = 'filetype',
				}, function(ft)
					require('snacks').scratch.open {
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
				require('snacks').scratch.select()
			end,
			{ desc = 'Select Scratch Buffer' },
		},
		{
			'<leader><leader>',
			function()
				require('snacks').picker.files {}
			end,
			{ silent = true },
			desc = 'Search Files',
		},
		{
			'<leader>b',
			function()
				require('snacks').picker.buffers {}
			end,
			{ silent = true },
			desc = 'Search [B]uffers',
		},
		{
			'<leader>h',
			function()
				require('snacks').picker.help {}
			end,
			{ silent = true },
			desc = 'Search [H]elp',
		},
		{
			'<Leader>o',
			function()
				require('snacks').picker.recent {}
			end,
			{ silent = true },
			desc = 'Search [O]ldfiles',
		},
		-- {
		-- 	'<Leader>-',
		-- 	function()
		-- 		require('snacks').picker.explorer {}
		-- 	end,
		-- 	{ silent = true },
		-- 	desc = 'Open file explorer',
		-- },
		{
			'\\',
			function()
				require('snacks').picker.grep {}
			end,
			{ silent = true },
			desc = 'grep project',
		},
		{
			'<leader>z',
			function()
				require('snacks').zen.zoom()
			end,
			{ silent = true },
			desc = 'Toggle buffer [z]oom mode',
		},
		{
			'<leader>ta',
			function()
				Snacks.picker.grep {
					title = 'Tasks',
					-- pass your desired search as a static pattern
					search = '^\\s*- \\[ \\]',
					-- we enable regex so the pattern is interpreted as a regex
					regex = true,
					-- no “live grep” needed here since we have a fixed pattern
					live = false,
					-- restrict search to the current working directory
					dirs = { vim.fn.getcwd() },
					-- include files ignored by .gitignore
					args = { '--no-ignore' },
					finder = 'grep',
					format = 'file',
					show_empty = true,
					supports_live = false,
					-- Start in normal mode
					on_show = function()
						vim.cmd.stopinsert()
					end,
				}
			end,
			desc = 'Search for incomplete t[a]sks',
		},
		{
			'<leader>to',
			function()
				Snacks.picker.grep {
					title = 'TODOs',
					-- Single pattern that matches:
					-- 1. Comment starters: //, #, --, %, ;, /*
					-- 2. Optional whitespace
					-- 3. Optional @ prefix
					-- 4. Markers: todo, note, bug, fixme (case insensitive)
					-- 5. Optional : suffix
					-- 6. Word boundary
					search = [[^\s*?(//|#|--|%|;|/\*)\s*@?(todo|note|hack|bug|fixme|fix|warn|xxx):?\b]],
					-- we enable regex so the pattern is interpreted as a regex
					regex = true,
					-- true to pass the complex regex to `rg`
					live = true,
					-- restrict search to the current working directory
					dirs = { vim.fn.getcwd() },
					-- include files ignored by .gitignore
					args = { '--no-ignore' },
					format = 'file',
					show_empty = true,
					supports_live = false,
					-- Start in normal mode
					on_show = function()
						vim.cmd.stopinsert()
					end,
				}
			end,
			desc = 'Search for t[o]dos',
		},
		-- Overrides default z=
		{
			'z=',
			function()
				---@diagnostic disable-next-line: undefined-field
				require('snacks').picker.spelling {}
			end,
			{ silent = true },
			desc = 'Spelling Suggestions',
		},
	},
	init = function()
		vim.g.custom_explorer = true
		-- disable all animations
		vim.g.snacks_animate = false

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

				-- Create some toggle mappings
				Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
				Snacks.toggle.diagnostics():map '<leader>ud'
				Snacks.toggle.inlay_hints():map '<leader>uh'
				Snacks.toggle.dim():map '<leader>uD'
			end,
		})

		vim.api.nvim_create_user_command('Zen', function()
			require('snacks').zen()
		end, { desc = 'Toggle Zen Mode' })

		vim.api.nvim_create_autocmd('User', {
			pattern = 'OilActionsPost',
			callback = function(event)
				if event.data.actions.type == 'move' then
					require('snacks').rename.on_rename_file(
						event.data.actions.src_url,
						event.data.actions.dest_url
					)
				end
			end,
		})
	end,
	opts = function(_, opts)
		-- Show select prompts relative to cursor position
		require('snacks.picker.config.layouts').select.layout.relative = 'cursor'
		-- Move explorer to the right
		require('snacks.picker.config.layouts').sidebar.layout.position = 'right'

		return vim.tbl_deep_extend('force', opts or {}, {
			quickfile = { enabled = false },
			scroll = { enabled = false },
			statuscolumn = { enabled = false },
			indent = { enabled = false },
			bigfile = {
				enabled = true,
				size = 1024 * 500, -- 500KB
			},
			image = {
				doc = {
					float = true,
					inline = false,
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
			picker = {
				matcher = {
					frecency = true,
				},
				icons = {
					ui = {
						live = '󰐰 ',
						hidden = '',
						ignored = '',
						unselected = '',
						selected = '✓ ',
					},
				},
				win = {
					preview = {
						wo = {
							foldcolumn = '0',
							number = false,
							relativenumber = false,
							statuscolumn = '',
						},
					},
					input = {
						keys = {
							['<Esc>'] = { 'close', mode = { 'n', 'i' } },
							['<c-t>'] = {
								'trouble_open',
								mode = { 'n', 'i' },
							},
						},
					},
					list = {
						wo = {
							conceallevel = 0,
						},
					},
				},
				prompt = utils.get_icon 'search',
				actions = require('trouble.sources.snacks').actions,
				previewers = {
					git = {
						native = true,
					},
				},
				sources = {
					files = {
						-- fd flags
						args = vim.fn.split(
							vim.fn.split(vim.env.FZF_DEFAULT_COMMAND, '/fd ')[2],
							' '
						),
					},
					buffers = {
						current = false,
						sort_lastused = true,
					},
					spelling = {
						layout = { preset = 'select' },
					},
				},
				formatters = {
					selected = {
						unselected = false,
					},
				},
				layouts = {
					default = {
						layout = {
							box = 'horizontal',
							width = 0.8,
							min_width = 120,
							height = 0.8,
							{
								box = 'vertical',
								border = utils.get_border(),
								title = '{source} {live}',
								title_pos = 'center',
								{ win = 'input', height = 1, border = 'bottom' },
								{ win = 'list', border = 'none' },
							},
							{ win = 'preview', border = utils.get_border(), width = 0.5 },
						},
					},
				},
			},
		})
	end,
}
