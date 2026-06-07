local pack = require '_.pack'

pack.add {
	{ src = 'https://tangled.org/ronshavit.com/mini.diff.jj' },
	{
		src = 'https://github.com/nvim-mini/mini.nvim',
		config = function()
			-- mini.nvim: core utilities (eager)
			local au = require '_.utils.au'
			local utils = require '_.utils'

			-- Bufremove keymap
			vim.keymap.set('n', '<M-d>', function()
				require('mini.bufremove').delete(0, false)
			end, {
				desc = 'Delete current buffer and open mini.starter if this was the last buffer',
			})

			-- Indentscope: disable in some buffers
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
				callback = function(args)
					vim.b[args.buf].miniindentscope_disable = true
				end,
			}

			local uv = vim.uv or vim.loop
			local width = 60

			local header = {
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
			}

			local quote = require('_.quotes').random_quote()

			local function unit(str, hl)
				return { string = str, type = 'empty', hl = hl }
			end

			local function line_width(line)
				local ret = 0
				for _, item in ipairs(line) do
					ret = ret + vim.api.nvim_strwidth(item.string)
				end
				return ret
			end

			local function pad_right(line, target)
				local missing = target - line_width(line)
				if missing > 0 then
					table.insert(line, unit((' '):rep(missing)))
				end
				return line
			end

			local function add_line(lines, line)
				table.insert(lines, pad_right(line, width))
			end

			local function add_blank(lines, count)
				for _ = 1, count do
					table.insert(lines, { unit '' })
				end
			end

			local function wrap_text(line)
				local wrapped_lines = {}
				local line_start = 1

				while line_start <= #line do
					local line_end = math.min(line_start + width - 1, #line)

					if line_end < #line then
						local space_pos = line:sub(line_start, line_end):find ' [^ ]*$'
						if space_pos then
							line_end = line_start + space_pos - 1
						end
					end

					local segment = line:sub(line_start, line_end):gsub('^%s*', '')
					if segment ~= '' then
						table.insert(wrapped_lines, segment)
					end

					line_start = line_end + 1
				end

				return wrapped_lines
			end

			local function filter_common(file)
				return file:match 'COMMIT_EDITMSG' == nil
					and file:match '/tmp' == nil
					-- vim help files
					and file:match '/share/nvim/runtime/doc' == nil
			end

			local function oldfiles(filter_map)
				filter_map = vim.tbl_extend('force', {
					[vim.fn.stdpath 'data'] = false,
					[vim.fn.stdpath 'cache'] = false,
					[vim.fn.stdpath 'state'] = false,
				}, filter_map or {})

				local filters = {}
				for path, want in pairs(filter_map) do
					table.insert(filters, { path = vim.fs.normalize(path), want = want })
				end

				local ret = {}
				local seen = {}
				for _, oldfile in ipairs(vim.v.oldfiles) do
					local file = vim.fs.normalize(oldfile)
					local want = not seen[file]
					seen[file] = true

					for _, filter in ipairs(filters) do
						local matches = file:sub(1, #filter.path) == filter.path
							and (
								file == filter.path
								or file:sub(#filter.path + 1, #filter.path + 1):find '[/\\]'
									~= nil
							)
						if matches ~= filter.want then
							want = false
							break
						end
					end

					if want and uv.fs_stat(file) then
						table.insert(ret, file)
					end
				end

				return ret
			end

			local function icon(name, category)
				local ok, mini_icons = pcall(require, 'mini.icons')
				if ok then
					local icon_text, icon_hl = mini_icons.get(category or 'file', name)
					return icon_text or '󰈔 ', icon_hl or 'Special'
				end

				return category == 'directory' and '󰉋 ' or '󰈔 ', 'Special'
			end

			local function edit_file(file)
				return function()
					vim.cmd('edit ' .. vim.fn.fnameescape(file))
				end
			end

			local function pack_update(opts)
				return function()
					if opts then
						vim.pack.update(nil, opts)
					else
						vim.pack.update()
					end
				end
			end

			local function pick_files()
				local fzf_ok, fzf = pcall(require, 'fzf-lua')
				if fzf_ok then
					fzf.files()
				end
			end

			local function read_session_or_pick()
				if _G.MiniSessions == nil then
					pick_files()
					return
				end

				local session_loaded = false
				vim.api.nvim_create_autocmd('SessionLoadPost', {
					once = true,
					callback = function()
						session_loaded = true
					end,
				})

				vim.defer_fn(function()
					if not session_loaded then
						pick_files()
					end
				end, 100)

				_G.MiniSessions.read()
			end

			local function get_git_root(path)
				path = vim.fs.normalize(path == '' and uv.cwd() or path)

				if uv.fs_stat(path .. '/.git') ~= nil then
					return path
				end

				for dir in vim.fs.parents(path) do
					if uv.fs_stat(dir .. '/.git') ~= nil then
						return vim.fs.normalize(dir)
					end
				end

				return vim.env.GIT_WORK_TREE
			end

			local function next_autokey(used)
				local keys =
					'1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
				keys = keys:gsub('[hjklq]', '')

				for key in pairs(used) do
					keys = keys:gsub(vim.pesc(key), '', 1)
				end

				return function()
					local key = keys:sub(1, 1)
					keys = keys:sub(2)
					return key
				end
			end

			local function bookmark_items()
				local items = {
					{
						key = 'e',
						icon = ' ',
						desc = 'New File',
						action = function()
							vim.cmd.enew()
						end,
					},
					{
						key = 'u',
						icon = '󰚰 ',
						desc = 'vim.pack Update',
						action = pack_update(),
					},
				}

				if #vim.pack.get(nil, { info = false }) > 0 then
					table.insert(items, {
						key = 's',
						icon = '󰑐 ',
						desc = 'vim.pack Sync',
						action = pack_update { target = 'lockfile' },
					})
				end

				vim.list_extend(items, {
					{
						key = 'l',
						icon = '󰏖 ',
						desc = 'vim.pack List',
						action = pack_update { offline = true },
					},
					{
						key = 't',
						icon = ' ',
						desc = 'Git Todo',
						action = edit_file '.git/todo.md',
					},
					{
						key = 'q',
						icon = ' ',
						desc = 'Quit',
						action = function()
							vim.cmd.quitall()
						end,
					},
				})

				return items
			end

			local function recent_file_items(opts, next_key)
				local root = opts.cwd
					and vim.fs.normalize(opts.cwd == true and vim.fn.getcwd() or opts.cwd)
				local filter_map = root and { [root] = true } or nil
				local ret = {}

				for _, file in ipairs(oldfiles(filter_map)) do
					if not opts.filter or opts.filter(file) then
						table.insert(ret, {
							key = next_key(),
							icon = 'file',
							file = file,
							desc = vim.fn.fnamemodify(file, ':t'),
							action = edit_file(file),
						})

						if #ret >= (opts.limit or 5) then
							break
						end
					end
				end

				return ret
			end

			local function project_items(next_key)
				local dirs = {}

				for _, file in ipairs(oldfiles()) do
					local dir = get_git_root(file)
					if dir and not vim.tbl_contains(dirs, dir) then
						table.insert(dirs, dir)
						if #dirs >= 5 then
							break
						end
					end
				end

				return vim.tbl_map(function(dir)
					return {
						key = next_key(),
						icon = 'directory',
						file = dir,
						desc = vim.fn.fnamemodify(dir, ':t'),
						action = function()
							vim.fn.chdir(dir)
							read_session_or_pick()
						end,
					}
				end, dirs)
			end

			local function path_units(file, path_width)
				local fname = vim.fn.fnamemodify(file, ':~')
				if #fname > path_width then
					fname = vim.fn.pathshorten(fname)
				end

				if #fname > path_width then
					local dir, file_name = fname:match '^(.*)/(.+)$'
					if dir and file_name then
						file_name = file_name:sub(-(path_width - #dir - 2))
						fname = dir .. '/…' .. file_name
					end
				end

				local dir, file_name = fname:match '^(.*)/(.+)$'
				if dir and file_name then
					return {
						unit(dir .. '/', 'MiniStarterDashboardDir'),
						unit(file_name, 'MiniStarterDashboardFile'),
					}
				end

				return { unit(fname, 'MiniStarterDashboardFile') }
			end

			local function add_title(lines, title, file)
				local line = { unit(title, 'MiniStarterDashboardTitle') }
				if file then
					vim.list_extend(line, path_units(file, width))
				end
				add_line(lines, line)
				add_blank(lines, 1)
			end

			local function add_header(lines)
				for _, text in ipairs(header) do
					local line = { unit(text, 'MiniStarterDashboardHeader') }
					local left = math.max(math.floor((width - line_width(line)) / 2), 0)
					if left > 0 then
						table.insert(line, 1, unit((' '):rep(left)))
					end
					add_line(lines, line)
				end
				add_blank(lines, 2)
			end

			local function add_quote(lines)
				for _, line in ipairs(quote) do
					if line == '' then
						add_blank(lines, 1)
					else
						local hl = line:match '^—' and 'MiniStarterDashboardAuthor'
							or 'MiniStarterDashboardQuote'
						for _, wrapped_line in ipairs(wrap_text(line)) do
							add_line(lines, { unit(wrapped_line, hl) })
						end
					end
				end
				add_blank(lines, 2)
			end

			local function add_action(lines, item)
				local icon_text, icon_hl = item.icon, 'MiniStarterDashboardIcon'
				if item.icon == 'file' or item.icon == 'directory' then
					icon_text, icon_hl = icon(item.file, item.icon)
				end

				local left = pad_right({ unit(icon_text, icon_hl) }, 2)
				table.insert(left, unit ' ')

				local right = { unit(' ' .. item.key, 'MiniStarterDashboardKey') }
				local center_width = width - line_width(left) - line_width(right)
				local center = item.file and path_units(item.file, center_width)
					or { unit(item.desc, 'MiniStarterDashboardFile') }

				item.name = item.desc
				center[#center].type = 'item'
				center[#center].item = item
				pad_right(center, center_width)

				local line = {}
				vim.list_extend(line, left)
				vim.list_extend(line, center)
				vim.list_extend(line, right)
				add_line(lines, line)
			end

			local function add_actions(lines, items, action_items)
				for _, item in ipairs(items) do
					table.insert(action_items, item)
					add_action(lines, item)
				end
				if #items > 0 then
					add_blank(lines, 1)
				end
			end

			local function apply_window_padding(lines, buf_id)
				local win = vim.fn.bufwinid(buf_id)
				local win_width = win > 0 and vim.api.nvim_win_get_width(win)
					or vim.o.columns
				local win_height = win > 0 and vim.api.nvim_win_get_height(win)
					or vim.o.lines
				win_height = win_height + (vim.o.laststatus >= 2 and 1 or 0)

				local left = math.max(math.floor((win_width - width) / 2), 0)
				local top = math.max(math.floor((win_height - #lines) / 2), 0)

				for _, line in ipairs(lines) do
					local line_left = left
					local overflow = line_width(line) - width
					if overflow > 0 then
						line_left = line_left - math.floor(overflow / 2)
					end
					table.insert(line, 1, unit((' '):rep(math.max(line_left, 0))))
				end

				for _ = 1, top do
					table.insert(lines, 1, { unit '' })
				end
			end

			local function map_action_keys(buf, items)
				local keys = {}
				for _, item in ipairs(items) do
					keys[item.key] = true
					vim.keymap.set('n', item.key, item.action, {
						buffer = buf,
						nowait = true,
						silent = true,
						desc = 'Dashboard action',
					})
				end

				for key in pairs(vim.b[buf].starter_dashboard_keys or {}) do
					if not keys[key] then
						pcall(vim.keymap.del, 'n', key, { buffer = buf })
					end
				end
				vim.b[buf].starter_dashboard_keys = keys
			end

			local function render_dashboard(_, buf_id)
				local bookmarks = bookmark_items()
				local used_keys = {}
				for _, item in ipairs(bookmarks) do
					used_keys[item.key] = true
				end

				local next_key = next_autokey(used_keys)
				local cwd = uv.cwd()
				local lines = {}
				local action_items = {}

				add_header(lines)
				add_quote(lines)
				add_title(lines, 'Bookmarks')
				add_actions(lines, bookmarks, action_items)
				add_title(lines, 'MRU ', vim.fn.fnamemodify('.', ':~'))
				add_actions(
					lines,
					recent_file_items(
						{ cwd = true, limit = 8, filter = filter_common },
						next_key
					),
					action_items
				)
				add_title(lines, 'MRU')
				add_actions(
					lines,
					recent_file_items({
						limit = 8,
						filter = function(file)
							return file:find(cwd, 1, true) == nil and filter_common(file)
						end,
					}, next_key),
					action_items
				)
				add_title(lines, 'Sessions')
				add_actions(lines, project_items(next_key), action_items)

				apply_window_padding(lines, buf_id)
				map_action_keys(buf_id, action_items)
				return lines
			end

			-- Configure mini modules
			-- Eager: cmdline, input, pick, starter, misc (auto_root, termbg_sync, restore_cursor)
			require('mini.cmdline').setup {}

			local input = require 'mini.input'
			input.setup {
				scope = 'cursor',
				handlers = {
					view = input.gen_view.floatwin {
						adjust_config = function(_, config)
							local max_width = math.max(vim.o.columns - 4, 1)
							config.border = utils.get_border()
							config.title_pos = 'center'
							config.width = math.min(math.max(config.width, 45), max_width)
							return config
						end,
					},
				},
			}

			require('mini.starter').setup {
				autoopen = true,
				evaluate_single = false,
				items = { { name = 'Dashboard', action = '', section = '' } },
				header = '',
				footer = '',
				content_hooks = { render_dashboard },
			}

			vim.api.nvim_create_autocmd('User', {
				group = vim.api.nvim_create_augroup(
					'custom_mini_starter_dashboard',
					{ clear = true }
				),
				pattern = 'MiniStarterOpened',
				callback = function()
					local buf = vim.api.nvim_get_current_buf()
					if vim.bo[buf].filetype == 'ministarter' then
						vim.b[buf].miniindentscope_disable = true
					end
				end,
			})

			local misc = require 'mini.misc'
			misc.setup {}

			misc.setup_auto_root()
			misc.setup_termbg_sync()
			misc.setup_restore_cursor()

			local function setup_clue()
				local clue = require 'mini.clue'

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
						:unique(function(mark)
							return mark.mark
						end)
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

				clue.setup {
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
						{ mode = 'n', keys = '<leader>t', desc = '+tabs' },
						{ mode = 'n', keys = '<leader>g', desc = '+git' },
						{ mode = 'x', keys = '<leader>g', desc = '+git' },
						{ mode = 'n', keys = '[', desc = '+prev' },
						{ mode = 'n', keys = ']', desc = '+next' },
						-- Enhance this by adding descriptions for <Leader> mapping groups
						clue.gen_clues.builtin_completion(),
						clue.gen_clues.g(),
						clue.gen_clues.marks(),
						clue.gen_clues.registers(),
						clue.gen_clues.windows(),
						clue.gen_clues.z(),
						clue.gen_clues.square_brackets(),
						-- Custom extras.
						mark_clues,
						macro_clues,
					},
					window = {
						delay = 150,
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
			end

			local function setup_hipatterns()
				local hipatterns = require 'mini.hipatterns'
				local extra = require 'mini.extra'
				local color_icon = utils.get_icon 'virtual' .. ' '

				local function highlight_if_ts_capture(capture, hl_group)
					return function(buf_id, _match, data)
						local captures = vim.treesitter.get_captures_at_pos(
							buf_id,
							data.line - 1,
							data.from_col - 1
						)

						local pred = function(t)
							return t.capture == capture
						end

						local not_in_capture =
							vim.tbl_isempty(vim.tbl_filter(pred, captures))

						if not_in_capture then
							return nil
						end

						return hl_group
					end
				end

				-- Returns hex color group for matching short hex color.
				--
				---@param match string
				---@return string
				local function get_hex_short(match)
					local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
					local hex = string.format('#%s%s%s%s%s%s', r, r, g, g, b, b)
					return hex
				end

				-- Returns hex color group for matching rgb() color.
				--
				---@param match string
				---@return string
				local function rgb_color(match)
					local red, green, blue = match:match 'rgb%((%d+), ?(%d+), ?(%d+)%)'
					local hex = string.format('#%02x%02x%02x', red, green, blue)
					return hex
				end

				-- Returns hex color group for matching rgba() color
				-- or false if alpha is nil or out of range.
				-- The use of the alpha value refers to a black background.
				--
				---@param match string
				---@return string|false
				local function rgba_color(match)
					local red, green, blue, alpha =
						match:match 'rgba%((%d+), ?(%d+), ?(%d+), ?(%d*%.?%d*)%)'
					alpha = tonumber(alpha)
					if alpha == nil or alpha < 0 or alpha > 1 then
						return false
					end
					local hex = string.format(
						'#%02x%02x%02x',
						red * alpha,
						green * alpha,
						blue * alpha
					)

					return hex
				end

				-- Returns extmark opts for highlights with virtual inline text.
				--
				---@param data table Includes `hl_group`, `full_match` and more.
				---@return table
				local function extmark_opts_inline(_, _, data)
					return {
						virt_text = { { color_icon, data.hl_group } },
						virt_text_pos = 'inline',
						-- priority = 200,
						right_gravity = false,
					}
				end

				local function get_highlight(cb)
					return function(_, match)
						local style = 'fg' -- 'fg' or 'bg', for extmark_opts_inline use 'fg'
						return hipatterns.compute_hex_color_group(cb(match), style)
					end
				end

				local comments = {}
				for _, word in ipairs {
					'todo',
					'note',
					'hack',
					'fixme',
					{ 'warn', 'hack' },
					{ 'bug', 'fixme' },
					{ 'fix', 'fixme' },
					{ 'xxx', 'fixme' },
				} do
					local w = type(word) == 'table' and word[1] or word
					local hl = type(word) == 'table' and word[2] or word

					if type(w) ~= 'string' or type(hl) ~= 'string' then
						return
					end

					comments[w] = extra.gen_highlighter.words(
						-- Highlights patterns like FOO, @FOO, @FOO: FOO:, upper, lowercase
						-- and sentence-cased (Foo)
						{ w, w:upper(), w:sub(1, 1):upper() .. w:sub(2) },
						-- Only inside comments
						highlight_if_ts_capture(
							'comment',
							string.format(
								'MiniHipatterns%s',
								hl:sub(1, 1):upper() .. hl:sub(2)
							)
						)
					)
				end

				hipatterns.setup {
					highlighters = vim.tbl_extend('force', comments, {
						-- Highlight hex color strings (`#rrggbb`) using that color
						hex_color = hipatterns.gen_highlighter.hex_color {
							style = 'bg',
							inline_text = color_icon,
						},
						-- `#rgb`
						hex_color_short = {
							pattern = '#%x%x%x%f[%X]',
							group = get_highlight(get_hex_short),
							extmark_opts = extmark_opts_inline,
						},
						-- `rgb(255, 255, 255)`
						rgb_color = {
							pattern = 'rgb%(%d+, ?%d+, ?%d+%)',
							group = get_highlight(rgb_color),
							extmark_opts = extmark_opts_inline,
						},
						-- `rgba(255, 255, 255, 0.5)`
						rgba_color = {
							pattern = 'rgba%(%d+, ?%d+, ?%d+, ?%d*%.?%d*%)',
							group = get_highlight(rgba_color),
							extmark_opts = extmark_opts_inline,
						},
					}),
				}
			end

			-- Scheduled: editing modules, diff, and icons
			vim.schedule(function()
				setup_hipatterns()
				setup_clue()

				-- TODO clean up my mappings that conflicts
				require('mini.bracketed').setup {}

				local extra = require 'mini.extra'
				extra.setup {}

				local ai = require 'mini.ai'

				ai.setup {
					-- Table with textobject id as fields, textobject specification as values.
					-- Also use this to disable builtin textobjects. See |MiniAi.config|.
					custom_textobjects = {
						B = extra.gen_ai_spec.buffer(),
						I = extra.gen_ai_spec.indent(),
						L = extra.gen_ai_spec.line(),

						-- For more complicated textobjects that require structural awareness,
						-- use tree-sitter. This example makes `aF`/`iF` mean around/inside function
						-- definition (not call). See `:h MiniAi.gen_spec.treesitter()` for details.
						F = ai.gen_spec.treesitter {
							a = '@function.outer',
							i = '@function.inner',
						},
					},
					search_method = 'cover',
					-- I work with big files sometimes, 50 is too low.
					n_lines = 20000,
				}

				-- Surround
				require('mini.surround').setup {
					search_method = 'cover_or_next',
				}

				-- Diff
				require('mini.diff').setup {
					sources = {
						require 'mini.diff.jj',
					},
					view = {
						style = 'sign',
						signs = {
							add = '│',
							change = '│',
							delete = '_',
						},
					},
				}

				-- Icons
				local test_icon = ''
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
					filetype = {
						copilot = { glyph = '', hl = 'MiniIconsGrey' },
						supermaven = { glyph = '', hl = 'MiniIconsGrey' },
						codecompanion = { glyph = '󰚩', hl = 'MiniIconsGrey' },
						gemini = { glyph = '⯌', hl = 'MiniIconsGrey' },
						gemini_cli = { glyph = '⯌', hl = 'MiniIconsGrey' },
						claude = { glyph = '', hl = 'MiniIconsGrey' },
						anthropic = { glyph = '', hl = 'MiniIconsGray' },
						openai = { glyph = '󰊲', hl = 'MiniIconsGrey' },
						groq = { glyph = '', hl = 'MiniIconsGrey' },
						xai = { glyph = '', hl = 'MiniIconsGrey' },
						huggingface = { glyph = '', hl = 'MiniIconsGrey' },
					},
					lsp = {
						calc = { glyph = '󰃬', hl = 'MiniIconsGrey' },
						copilot = { glyph = '', hl = 'MiniIconsGrey' },
					},
					directory = {
						['.git'] = { glyph = '󰊢', hl = 'MiniIconsOrange' },
						['.github'] = { glyph = '󰊤', hl = 'MiniIconsAzure' },
					},
					file = {
						-- https://github.com/echasnovski/mini.nvim/issues/1384#issuecomment-2523472949
						['init.lua'] = { glyph = '󰢱', hl = 'MiniIconsAzure' },
						README = { glyph = '󰈙', hl = 'MiniIconsYellow' },
						['README.md'] = { glyph = '󰈙', hl = 'MiniIconsYellow' },
					},
				}
				require('mini.icons').mock_nvim_web_devicons()
			end)

			-- Sanitize a string to be safe for use as a filename.
			local function sanitize_for_filename(str)
				return str
					:gsub('[/%.~%^:%?%*%[\\@%s%c]+', '_')
					:gsub('_+', '_')
					:gsub('^_', '')
					:gsub('_$', '')
			end

			local function get_session_name()
				local name = sanitize_for_filename(vim.fn.getcwd())
				local obj = vim
					.system({ 'git', 'branch', '--show-current' }, { text = true })
					:wait()
				local branch = vim.trim(obj.stdout or '')
				if obj.code == 0 and branch ~= '' then
					return name .. '_' .. sanitize_for_filename(branch)
				else
					return name
				end
			end

			if vim.fn.argc(-1) == 0 then
				vim.schedule(function()
					local sessions = require 'mini.sessions'
					sessions.setup {
						file = '',
					}

					vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, {
						nested = true,
						callback = function()
							local session_name = get_session_name()

							-- Save session for current branch
							if vim.v.this_session ~= '' then
								sessions.write()
							end

							if
								sessions.detected[session_name]
								and string.find(vim.v.this_session, session_name, 1, true)
									== nil
							then
								return
							else
								-- If we are opening a new branch, create a session for the new branch with current state
								sessions.write(get_session_name())
							end
						end,
					})

					vim.api.nvim_create_autocmd('VimLeavePre', {
						callback = function()
							if vim.v.this_session == '' then
								return
							end

							sessions.write(get_session_name())
						end,
					})
				end)
			end
		end,
	},
}
