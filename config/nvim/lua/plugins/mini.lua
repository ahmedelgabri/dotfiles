return {
	{
		'https://github.com/echasnovski/mini.align',
		keys = {
			{ 'ga', mode = { 'n', 'x' } },
			{ 'gA', mode = { 'n', 'x' } },
		},
		config = function()
			require('mini.align').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.bufremove',
		keys = {
			{ '<M-d>', ':lua MiniBufremove.delete(0, true)<CR>' },
		},
		config = function()
			require('mini.bufremove').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.indentscope',
		config = function()
			-- disable in some buffers
			vim.api.nvim_create_autocmd('FileType', {
				pattern = {
					'fzf',
					'startify',
					'starter',
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
			})

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
		config = function()
			require('mini.pairs').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.surround',
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
		config = function()
			require('mini.trailspace').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.hipatterns',
		config = function()
			local hipatterns = require 'mini.hipatterns'
			hipatterns.setup {
				highlighters = {
					-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE', 'BUG'
					fixme = {
						pattern = '%f[%w]()FIXME()%f[%W]',
						group = 'MiniHipatternsFixme',
					},
					bug = {
						pattern = '%f[%w]()BUG()%f[%W]',
						group = 'MiniHipatternsFixme',
					},
					hack = {
						pattern = '%f[%w]()HACK()%f[%W]',
						group = 'MiniHipatternsHack',
					},
					todo = {
						pattern = '%f[%w]()TODO()%f[%W]',
						group = 'MiniHipatternsTodo',
					},
					note = {
						pattern = '%f[%w]()NOTE()%f[%W]',
						group = 'MiniHipatternsNote',
					},

					-- Highlight hex color strings (`#rrggbb`) using that color
					hex_color = hipatterns.gen_highlighter.hex_color(),
				},
			}
		end,
	},
	{
		'https://github.com/echasnovski/mini.diff',
		config = function()
			require('mini.diff').setup {
				view = {
					signs = {
						add = '│',
						change = '│',
						delete = '_',
					},
				},
			}
		end,
	},
	{
		'https://github.com/echasnovski/mini.starter',
		config = function()
			local starter = require 'mini.starter'
			local au = require '_.utils.au'

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

			local my_items = {
				-- Use this if you set up 'mini.sessions'
				-- starter.sections.sessions(5, true),
				starter.sections.builtin_actions(),
				starter.sections.recent_files(10),
				starter.sections.recent_files(10, true, false),
				{
					name = 'Sync',
					action = 'Lazy sync',
					section = 'Commands',
				},
				{
					name = 'Update',
					action = 'Lazy update',
					section = 'Commands',
				},
				{
					name = 'Clean',
					action = 'Lazy clean',
					section = 'Commands',
				},
				{
					name = 'Profile',
					action = 'Lazy profile',
					section = 'Commands',
				},
				{
					name = 'Git Todo',
					action = 'e .git/todo.md',
					section = 'Bookmarks',
				},
			}

			local function findHighestValue(tbl, cb)
				if cb == nil then
					cb = function(x)
						return x
					end
				end
				local highest = cb(tbl[1])
				for i = 2, #tbl do
					highest = math.max(highest, cb(tbl[i]))
				end
				return highest
			end

			local function centeredHeader(header)
				local mid = math.floor(vim.o.tw / 2)
				local midStr = math.floor(findHighestValue(header, string.len) / 4)
				local space = math.floor(mid - midStr)

				return vim.tbl_map(function(a)
					return vim.fn['repeat'](' ', space) .. a
				end, header)
			end

			starter.setup {
				evaluate_single = true,
				items = my_items,
				header = table.concat({
					table.concat(
						centeredHeader {
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
						},
						'\n'
					),
					'',
					vim.fn['repeat']('▁', vim.o.textwidth),
					'',
					random_quote(),
					vim.fn['repeat']('▔', vim.o.textwidth),
				}, '\n'),
				footer = 'ϟ ' .. (vim.fn.has 'nvim' and 'nvim' or 'vim') .. '.',
				content_hooks = {
					starter.gen_hook.adding_bullet '  ',
					starter.gen_hook.aligning('center', 'center'),
					starter.gen_hook.indexing(
						'all',
						{ 'Builtin actions', 'Bookmarks', 'Commands' }
					),
				},
			}

			au.augroup('__mini_start__', {
				{
					event = 'User',
					pattern = 'MiniStarterOpened',
					callback = function(args)
						vim.cmd [[setlocal cursorline]]
						vim.keymap.set('n', 'j', function()
							MiniStarter.update_current_item 'next'
						end, { buffer = args.buf })
						vim.keymap.set('n', 'k', function()
							MiniStarter.update_current_item 'prev'
						end, { buffer = args.buf })
					end,
				},
			})
		end,
	},
	-- {
	-- 	'https://github.com/echasnovski/mini.sessions',
	-- 	config = function()
	-- 		require('mini.sessions').setup {}
	-- 	end,
	-- },
}
