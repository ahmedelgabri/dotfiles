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
			vim.cmd [[hi! link MiniIndentscopeSymbol Comment]]
			vim.cmd [[hi! link MiniIndentscopeSymbolOff Comment]]

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
	-- {
	-- 	'https://github.com/echasnovski/mini.starter',
	-- 	config = function()
	-- 		local starter = require 'mini.starter'

	-- 		local my_items = {}

	-- 		starter.setup {
	-- 			evaluate_single = true,
	-- 			items = {
	-- 				-- Use this if you set up 'mini.sessions'
	-- 				-- starter.sections.sessions(5, true),
	-- 				starter.sections.builtin_actions(),
	-- 				starter.sections.recent_files(10, false),
	-- 				starter.sections.recent_files(10, true),
	-- 				{
	-- 					name = 'Lazy Sync',
	-- 					action = 'Lazy sync',
	-- 					section = 'Commands',
	-- 				},
	-- 				{
	-- 					name = 'Lazy Update',
	-- 					action = 'Lazy update',
	-- 					section = 'Commands',
	-- 				},
	-- 				{
	-- 					name = 'Lazy Clean',
	-- 					action = 'Lazy clean',
	-- 					section = 'Commands',
	-- 				},
	-- 				{
	-- 					name = 'Lazy Profile',
	-- 					action = 'Lazy Profile',
	-- 					section = 'Commands',
	-- 				},
	-- 				{
	-- 					name = '.git/todo.md',
	-- 					action = 'e .git/todo.md',
	-- 					section = 'Bookmarks',
	-- 				},
	-- 			},
	-- 			content_hooks = {
	-- 				starter.gen_hook.adding_bullet '• ',
	-- 				starter.gen_hook.indexing('all', { 'Builtin actions' }),
	-- 				starter.gen_hook.padding(3, 2),
	-- 			},
	-- 		}
	-- 	end,
	-- },
	-- {
	-- 	'https://github.com/echasnovski/mini.sessions',
	-- 	config = function()
	-- 		require('mini.sessions').setup {}
	-- 	end,
	-- },
}
