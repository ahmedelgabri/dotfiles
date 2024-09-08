local au = require '_.utils.au'

return {
	{
		'https://github.com/echasnovski/mini.icons',
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
					copilot = { glyph = '', hl = 'MiniIconsOrange' },
					supermaven = { glyph = '', hl = 'MiniIconsYellow' },
					calc = { glyph = '󰃬', hl = 'MiniIconsGrey' },
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
		'https://github.com/echasnovski/mini.files',
		lazy = false,
		keys = {
			{
				'-',
				function()
					MiniFiles.open()
				end,
				noremap = true,
				desc = 'Open current directory',
			},
			{
				'<leader>-',
				function()
					MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
					MiniFiles.reveal_cwd()
				end,
				noremap = true,
				desc = 'Open current buffer',
			},
		},
		config = function()
			-- Add space after the icon
			local prefix = function(fs_entry)
				local icon, hl = MiniFiles.default_prefix(fs_entry)
				return icon .. ' ', hl
			end

			require('mini.files').setup {
				mappings = {
					go_in_plus = '<CR>',
					show_help = '?',
				},
				content = {
					prefix = prefix,
				},
			}
		end,
	},
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

					require('mini.starter').open()
				end,
				desc = 'Delete current buffer and open mini.starter if this was the last buffer',
			},
		},
	},
	{
		'https://github.com/echasnovski/mini.indentscope',
		event = 'VeryLazy',
		config = function()
			-- disable in some buffers
			au.autocmd {
				event = { 'FileType' },
				pattern = {
					'fzf',
					'startify',
					'ministarter',
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
		event = 'VeryLazy',
		config = function()
			require('mini.pairs').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.ai',
		event = 'VeryLazy',
		config = function()
			require('mini.ai').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.surround',
		event = 'VeryLazy',
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
		event = 'VeryLazy',
		config = function()
			require('mini.trailspace').setup {}
		end,
	},
	{
		'https://github.com/echasnovski/mini.hipatterns',
		event = 'BufReadPost',
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
		event = 'VeryLazy',
		config = function()
			require('mini.diff').setup {
				view = {
					style = 'sign',
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
		'https://github.com/echasnovski/mini.clue',
		event = 'VeryLazy',
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
	{
		'https://github.com/echasnovski/mini.starter',
		config = function()
			vim.api.nvim_create_autocmd('User', {
				pattern = 'LazyVimStarted',
				callback = function(ev)
					local starter = require 'mini.starter'
					local stats = require('lazy').stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					starter.config.footer = function()
						return 'ϟ Lazy\n'
							.. 'plugins: '
							.. stats.loaded
							.. '/'
							.. stats.count
							.. '\nStartup time: '
							.. ms
							.. ' ms'
					end
					-- https://github.com/LazyVim/LazyVim/commit/eb6c9fb5784a8001c876203de174cd79e96bb637
					if vim.bo[ev.buf].filetype == 'ministarter' then
						pcall(starter.refresh)
					end
				end,
			})

			local starter = require 'mini.starter'
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

			local exclude = {
				'COMMIT_EDITMSG',
				'/tmp',
				string.gsub(
					vim.fn.escape(
						vim.fn.fnamemodify(vim.fn.resolve(vim.env.VIMRUNTIME), ':p'),
						'\\'
					) .. 'doc',
					'%-',
					'%%-'
				),
				'/vimwiki/',
			}

			-- https://github.com/echasnovski/mini.nvim/discussions/776#discussioncomment-8959196
			local function recent_files(opts)
				local n, current_dir, show_path, skip_current_dir =
					opts.n, opts.current_dir, opts.show_path, opts.skip_current_dir

				n = n or 5
				if current_dir == nil then
					current_dir = false
				end

				if show_path == nil then
					show_path = true
				end

				if show_path == false then
					show_path = function()
						return ''
					end
				end

				if show_path == true then
					show_path = function(path)
						return string.format(' (%s)', vim.fn.fnamemodify(path, ':~:.'))
					end
				end

				if not vim.is_callable(show_path) then
					vim.api.nvim_err_writeln '`show_path` should be boolean or callable.'
				end

				return function()
					local section = string.format(
						'Recent files%s',
						current_dir
								and ' (' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~') .. ')'
							or ''
					)

					-- Use only actual readable files
					local files = vim.tbl_filter(function(f)
						return vim.fn.filereadable(f) == 1
					end, vim.v.oldfiles or {})

					if #files == 0 then
						return {
							{
								name = 'There are no recent files (`v:oldfiles` is empty)',
								action = '',
								section = section,
							},
						}
					end

					local sep = vim.loop.os_uname().sysname == 'Windows_NT' and [[%\]]
						or '%/'
					local cwd_pattern = '^' .. vim.pesc(vim.fn.getcwd()) .. sep

					-- Possibly filter files from current directory
					if current_dir then
						-- Use only files from current directory and its subdirectories
						files = vim.tbl_filter(function(f)
							return f:find(cwd_pattern) ~= nil
						end, files)
					end

					if skip_current_dir then
						-- Use only files from current directory and its subdirectories
						files = vim.tbl_filter(function(f)
							return f:find(cwd_pattern) == nil
						end, files)
					end

					if #files == 0 then
						return {
							{
								name = 'There are no recent files in current directory',
								action = '',
								section = section,
							},
						}
					end

					-- Create items
					local items = {}

					local data = vim.tbl_filter(function(f)
						local filtered = vim.tbl_filter(function(ex)
							return string.match(f, ex) == nil
						end, exclude)

						return #filtered == #exclude
					end, files)

					for _, f in ipairs(vim.list_slice(data, 1, n)) do
						local name = vim.fn.fnamemodify(f, ':t') .. show_path(f)
						table.insert(
							items,
							{ action = 'edit ' .. f, name = name, section = section }
						)
					end

					return items
				end
			end

			-- A workaround to centralize everything.
			-- `aligning("center", "center")` will centralize the longest line in
			-- `content`, then left align other items to its beginning.
			-- It causes the header to not be truly centralized and have a variable
			-- shift to the left.
			-- This function will use `aligning` and pad the header accordingly.
			local centralize = function()
				return function(content, buf_id)
					-- Get max line width, same as in `aligning`
					local max_line_width = math.max(unpack(vim.tbl_map(function(l)
						return vim.fn.strdisplaywidth(l)
					end, starter.content_to_lines(content))))

					-- Align
					content =
						starter.gen_hook.aligning('center', 'center')(content, buf_id)

					-- Iterate over header items and pad with relative missing spaces
					local coords = starter.content_coords(content, 'header')
					for _, c in ipairs(coords) do
						local unit = content[c.line][c.unit]
						local pad = (max_line_width - vim.fn.strdisplaywidth(unit.string))
							/ 2
						if unit.string ~= '' then
							unit.string = string.rep(' ', pad) .. unit.string
						end
					end

					return content
				end
			end

			starter.setup {
				evaluate_single = true,
				items = {
					-- Use this if you set up 'mini.sessions'
					-- starter.sections.sessions(5, true),
					recent_files { n = 10, current_dir = true, show_path = false },
					recent_files { n = 10, skip_current_dir = true },
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
					starter.sections.builtin_actions(),
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
				footer = 'ϟ ' .. (vim.fn.has 'nvim' and 'nvim' or 'vim') .. '.',
				content_hooks = {
					starter.gen_hook.adding_bullet '',
					centralize(),
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
						vim.opt_local.cursorline = true
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
