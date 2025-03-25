---@diagnostic disable: missing-fields
local utils = require '_.utils'

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
			'<Leader>-',
			function()
				require('snacks').picker.explorer {
					win = {
						list = {
							keys = {
								['o'] = { { 'pick_win', 'jump' }, mode = { 'n', 'i' } },
							},
						},
					},
				}
			end,
			{ silent = true },
			desc = 'Open file explorer',
		},
		{
			'<leader>z',
			function()
				require('snacks').zen.zoom()
			end,
			{ silent = true },
			desc = 'Toggle buffer [z]oom mode',
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

		local random_quote = function()
			local quotes = require '_.quotes'
			math.randomseed(os.time())

			return quotes[math.random(#quotes)]
		end

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
				enabled = true,
				pane_gap = 10,
				preset = {
					keys = {
						{
							key = 'e',
							icon = ' ',
							desc = 'New File',
							action = ':ene',
						},
						{
							desc = 'Sync',
							icon = '󰒲 ',
							action = ':Lazy sync',
							key = 's',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Clean',
							icon = '󰒲 ',
							action = ':Lazy clean',
							key = 'c',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							desc = 'Lazy',
							icon = '󰒲 ',
							action = ':Lazy',
							key = 'l',
							enabled = package.loaded.lazy ~= nil,
						},
						{
							icon = ' ',
							desc = 'Git Todo',
							action = ':e .git/todo.md',
							key = 't',
						},
						{ icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
					},
					header = table.concat({
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
				},
				sections = {
					{ section = 'header' },
					vim.tbl_map(function(line)
						return {
							text = { wrap_text({ line }, 60), hl = 'Constant' },
							gap = 1,
						}
					end, random_quote()),
					{ text = '', padding = 1 },
					{ title = 'Bookmarks', padding = 1 },
					{ section = 'keys', padding = 1 },
					{ title = 'MRU', padding = 1 },
					{ section = 'recent_files', limit = 8, padding = 1 },
					{ title = 'Sessions', padding = 1 },
					{ section = 'projects', padding = 1 },
					{ section = 'startup' },
				},
			},
		})
	end,
}
