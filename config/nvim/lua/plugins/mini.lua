local au = require '_.utils.au'
local utils = require '_.utils'

return {
	{
		'https://github.com/echasnovski/mini.icons',
		event = utils.LazyFile,
		config = function()
			local test_icon = ''
			local js_table = { glyph = test_icon, hl = 'MiniIconsYellow' }
			local jsx_table = { glyph = test_icon, hl = 'MiniIconsAzure' }
			local ts_table = { glyph = test_icon, hl = 'MiniIconsAzure' }
			local tsx_table = { glyph = test_icon, hl = 'MiniIconsBlue' }

			require('mini.icons').setup {
				extension = {
					['test.js'] = js_table,
					['test.jsx'] = jsx_table,
					['test.ts'] = ts_table,
					['test.tsx'] = tsx_table,
					['spec.js'] = js_table,
					['spec.jsx'] = jsx_table,
					['spec.ts'] = ts_table,
					['spec.tsx'] = tsx_table,
				},
				lsp = {
					copilot = { glyph = '', hl = 'MiniIconsOrange' },
					supermaven = { glyph = '', hl = 'MiniIconsYellow' },
					calc = { glyph = '󰃬', hl = 'MiniIconsGrey' },
					codecompanion = { glyph = '󰚩', hl = 'MiniIconsGrey' },
				},
				directory = {
					['.git'] = { glyph = '󰊢', hl = 'MiniIconsOrange' },
					['.github'] = { glyph = '󰊤', hl = 'MiniIconsAzure' },
				},
				file = {
					README = { glyph = '󰈙', hl = 'MiniIconsYellow' },
					['README.md'] = { glyph = '󰈙', hl = 'MiniIconsYellow' },
				},
			}
			require('mini.icons').mock_nvim_web_devicons()
		end,
	},
	{
		'https://github.com/echasnovski/mini.align',
		keys = {
			{ 'ga', mode = { 'n', 'x' } },
			{ 'gA', mode = { 'n', 'x' } },
		},
		opts = {},
	},
	{
		'https://github.com/echasnovski/mini.bufremove',
		opts = {},
		keys = {
			{
				'<M-d>',
				function()
					require('mini.bufremove').delete(0, false)

					local buf_id = vim.api.nvim_get_current_buf()
					local is_empty = vim.api.nvim_buf_get_name(buf_id) == ''
						and vim.bo[buf_id].filetype == ''

					if not is_empty then
						return
					end

					Snacks.dashboard.open()
				end,
				desc = 'Delete current buffer and open mini.starter if this was the last buffer',
			},
		},
	},
	{
		'https://github.com/echasnovski/mini.indentscope',
		event = utils.LazyFile,
		init = function()
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
					'mason',
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			}
		end,
		config = function()
			require('mini.indentscope').setup {
				draw = {
					delay = 50,
					animation = require('mini.indentscope').gen_animation.none(),
				},
				symbol = '│', -- default ╎, -- alts: ┊│┆ ┊  ▎││ ▏▏
			}
		end,
	},
	{
		'https://github.com/echasnovski/mini.pairs',
		event = utils.LazyFile,
		opts = {},
	},
	{
		'https://github.com/echasnovski/mini.ai',
		event = utils.LazyFile,
		opts = {},
	},
	{
		'https://github.com/echasnovski/mini.surround',
		event = utils.LazyFile,
		config = function()
			require('mini.surround').setup {
				mappings = {
					add = 'ys',
					delete = 'ds',
					find = '',
					find_left = '',
					highlight = '',
					replace = 'cs',
					update_n_lines = '',

					-- Add this only if you don't want to use extended mappings
					suffix_last = '',
					suffix_next = '',
				},
				search_method = 'cover_or_next',
			}

			-- Remap adding surrounding to Visual mode selection
			vim.keymap.del('x', 'ys')
			vim.keymap.set(
				'x',
				'S',
				[[:<C-u>lua MiniSurround.add('visual')<CR>]],
				{ silent = true, desc = '[S]urround in visual mode' }
			)

			-- Make special mapping for "add surrounding for line"
			vim.keymap.set(
				'n',
				'yss',
				'ys_',
				{ remap = true, desc = 'Add surrounding for line' }
			)
		end,
	},
	{
		'https://github.com/echasnovski/mini.trailspace',
		event = utils.LazyFile,
		opts = {},
	},
	{
		'https://github.com/echasnovski/mini.hipatterns',
		event = utils.LazyFile,
		config = function()
			local hipatterns = require 'mini.hipatterns'

			local highlighters = {}
			for _, word in ipairs {
				'todo',
				'note',
				'hack',
				'fixme',
				{ 'warn', 'hack' },
				{ 'bug', 'fixme' },
				{ 'xxx', 'fixme' },
			} do
				local w = type(word) == 'table' and word[1] or word
				local hl = type(word) == 'table' and word[2] or word

				highlighters[w] = {
					-- Highlights patterns like FOO, @FOO, @FOO: FOO: both upper and lowercase
					pattern = {
						string.format('%%f[%%w]()@?%s%%s?:?()%%f[%%W]', w),
						string.format('%%f[%%w]()@?%s%%s?:?()%%f[%%W]', w:upper()),
					},
					group = string.format(
						'MiniHipatterns%s',
						hl:sub(1, 1):upper() .. hl:sub(2)
					),
				}
			end

			hipatterns.setup {
				highlighters = vim.tbl_extend('force', highlighters, {
					-- Highlight hex color strings (`#rrggbb`) using that color
					hex_color = hipatterns.gen_highlighter.hex_color(),
				}),
			}
		end,
	},
	{
		'https://github.com/echasnovski/mini.diff',
		event = utils.LazyFile,
		opts = {
			view = {
				style = 'sign',
				signs = {
					add = '│',
					change = '│',
					delete = '_',
				},
			},
		},
	},
	{
		'https://github.com/echasnovski/mini.clue',
		event = utils.LazyFile,
		config = function()
			local miniclue = require 'mini.clue'

			-- https://github.com/MariaSolOs/dotfiles/blob/8479ce37bc9bac5f8383d38aa3ead36dc935bdf1/.config/nvim/lua/plugins/miniclue.lua#L50

			-- Add a-z/A-Z marks.
			local function mark_clues()
				local marks = {}
				vim.list_extend(
					marks,
					vim.fn.getmarklist(vim.api.nvim_get_current_buf())
				)
				vim.list_extend(marks, vim.fn.getmarklist())

				return vim
					.iter(marks)
					:map(function(mark)
						local key = mark.mark:sub(2, 2)

						-- Just look at letter marks.
						if not string.match(key, '^%a') then
							return nil
						end

						-- For global marks, use the file as a description.
						-- For local marks, use the line number and content.
						local desc
						if mark.file then
							desc = vim.fn.fnamemodify(mark.file, ':p:~:.')
						elseif mark.pos[1] and mark.pos[1] ~= 0 then
							local line_num = mark.pos[2]
							local lines = vim.fn.getbufline(mark.pos[1], line_num)
							if lines and lines[1] then
								desc =
									string.format('%d: %s', line_num, lines[1]:gsub('^%s*', ''))
							end
						end

						if desc then
							return {
								mode = 'n',
								keys = string.format('`%s', key),
								desc = desc,
							}
						end
					end)
					:totable()
			end

			-- Clues for recorded macros.
			local function macro_clues()
				local res = {}
				for _, register in ipairs(vim.split('abcdefghijklmnopqrstuvwxyz', '')) do
					local keys = string.format('"%s', register)
					local ok, desc = pcall(vim.fn.getreg, register, 1)
					if ok and desc ~= '' then
						table.insert(res, { mode = 'n', keys = keys, desc = desc })
						table.insert(res, { mode = 'v', keys = keys, desc = desc })
					end
				end

				return res
			end

			miniclue.setup {
				triggers = {
					-- Leader triggers
					{ mode = 'n', keys = '<Leader>' },
					{ mode = 'x', keys = '<Leader>' },
					{ mode = 'n', keys = '<localleader>' },
					{ mode = 'x', keys = '<localleader>' },

					-- Built-in completion
					{ mode = 'i', keys = '<C-x>' },

					-- `g` key
					{ mode = 'n', keys = 'g' },
					{ mode = 'x', keys = 'g' },

					-- Marks
					{ mode = 'n', keys = "'" },
					{ mode = 'n', keys = '`' },
					{ mode = 'x', keys = "'" },
					{ mode = 'x', keys = '`' },

					-- Registers
					{ mode = 'n', keys = '"' },
					{ mode = 'x', keys = '"' },
					{ mode = 'i', keys = '<C-r>' },
					{ mode = 'c', keys = '<C-r>' },

					-- Window commands
					{ mode = 'n', keys = '<C-w>' },

					-- `z` key
					{ mode = 'n', keys = 'z' },
					{ mode = 'x', keys = 'z' },

					-- Moving between stuff.
					{ mode = 'n', keys = '[' },
					{ mode = 'n', keys = ']' },
				},

				clues = {
					-- TODO: I need to ogranize my key mappings better
					-- Leader/movement groups.
					-- { mode = 'n', keys = '<leader>b', desc = '+buffers' },
					-- { mode = 'n', keys = '<leader>c', desc = '+code' },
					-- { mode = 'x', keys = '<leader>c', desc = '+code' },
					-- { mode = 'n', keys = '<leader>d', desc = '+debug' },
					-- { mode = 'n', keys = '<leader>f', desc = '+find' },
					-- { mode = 'n', keys = '<leader>x', desc = '+loclist/quickfix' },
					{ mode = 'n', keys = '<leader>t', desc = '+tabs' },
					{ mode = 'n', keys = '<leader>g', desc = '+git' },
					{ mode = 'x', keys = '<leader>g', desc = '+git' },
					{ mode = 'n', keys = '[', desc = '+prev' },
					{ mode = 'n', keys = ']', desc = '+next' },
					-- Enhance this by adding descriptions for <Leader> mapping groups
					miniclue.gen_clues.builtin_completion(),
					miniclue.gen_clues.g(),
					miniclue.gen_clues.marks(),
					miniclue.gen_clues.registers(),
					miniclue.gen_clues.windows(),
					miniclue.gen_clues.z(),
					-- Custom extras.
					mark_clues,
					macro_clues,
				},
				window = {
					delay = 500,
					scroll_down = '<C-f>',
					scroll_up = '<C-b>',
					config = function(bufnr)
						local max_width = 0
						for _, line in
							ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
						do
							max_width = math.max(max_width, vim.fn.strchars(line))
						end

						-- Keep some right padding.
						max_width = max_width + 2

						return {
							border = 'rounded',
							-- Dynamic width capped at 45.
							width = math.min(45, max_width),
						}
					end,
				},
			}
		end,
	},
	-- {
	-- 	'https://github.com/echasnovski/mini.sessions',
	-- 	config = function()
	-- 		require('mini.sessions').setup {}
	-- 	end,
	-- },
}
