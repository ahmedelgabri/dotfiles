local au = require '_.utils.au'
local utils = require '_.utils'

return {
	{
		'https://github.com/nvim-mini/mini.nvim',
		keys = {
			-- Bufremove
			{
				'<M-d>',
				function()
					require('mini.bufremove').delete(0, false)
				end,
				desc = 'Delete current buffer and open mini.starter if this was the last buffer',
			},
		},

		init = function()
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

			au.autocmd {
				event = { 'User' },
				pattern = 'SnacksDashboardOpened',
				callback = function(args)
					vim.b[args.buf].miniindentscope_disable = true
				end,
			}
		end,
		config = function()
			-- TODO clean up my mappings that conflicts
			require('mini.bracketed').setup {}

			local extra = require 'mini.extra'
			extra.setup {}

			local misc = require 'mini.misc'
			misc.setup {}

			misc.setup_auto_root()
			misc.setup_termbg_sync()
			misc.setup_restore_cursor()

			require('mini.pairs').setup {
				-- https://github.com/echasnovski/mini.nvim/issues/835
				-- alternative? https://gist.github.com/tmerse/dc21ec932860013e56882f23ee9ad8d2
				mappings = {
					-- Prevents the action if the cursor is just before any character or next to a "\".
					['('] = {
						action = 'open',
						pair = '()',
						neigh_pattern = '[^\\][%s%)%]%}]',
					},
					['['] = {
						action = 'open',
						pair = '[]',
						neigh_pattern = '[^\\][%s%)%]%}]',
					},
					['{'] = {
						action = 'open',
						pair = '{}',
						neigh_pattern = '[^\\][%s%)%]%}]',
					},
					-- This is default (prevents the action if the cursor is just next to a "\").
					[')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
					[']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
					['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
					-- Prevents the action if the cursor is just before or next to any character.
					['"'] = {
						action = 'closeopen',
						pair = '""',
						neigh_pattern = '[^%w][^%w]',
						register = { cr = false },
					},
					["'"] = {
						action = 'closeopen',
						pair = "''",
						neigh_pattern = '[^%w][^%w]',
						register = { cr = false },
					},
					['`'] = {
						action = 'closeopen',
						pair = '``',
						neigh_pattern = '[^%w][^%w]',
						register = { cr = false },
					},
				},
			}

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
				-- 'mini.ai' by default mostly mimics built-in search behavior: first try
				-- to find textobject covering cursor, then try to find to the right.
				-- Although this works in most cases, some are confusing. It is more robus…
				-- always try to search only covering textobject and explicitly ask to sea…
				-- for next (`an`/`in`) or last (`an`/`il`).
				-- Try this. If you don't like it - delete next line and this comment.
				search_method = 'cover',
			}

			-- Surround
			require('mini.surround').setup {
				-- How to search for surrounding (first inside current line, then inside
				-- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
				-- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
				-- see `:h MiniSurround.config`.
				search_method = 'cover_or_next',
			}

			-- Diff
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

			-- Icons
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
				filetype = {
					copilot = { glyph = '', hl = 'MiniIconsGrey' },
					supermaven = { glyph = '', hl = 'MiniIconsGrey' },
					codecompanion = { glyph = '󰚩', hl = 'MiniIconsGrey' },
					gemini = { glyph = '⯌', hl = 'MiniIconsGrey' },
					gemini_cli = { glyph = '⯌', hl = 'MiniIconsGrey' },
					claude = { glyph = '', hl = 'MiniIconsGrey' },
					anthropic = { glyph = '', hl = 'MiniIconsGray' },
					openai = { glyph = '󰊲', hl = 'MiniIconsGrey' },
					groq = { glyph = '', hl = 'MiniIconsGrey' },
					xai = { glyph = '', hl = 'MiniIconsGrey' },
					huggingface = { glyph = '', hl = 'MiniIconsGrey' },
				},
				lsp = {
					calc = { glyph = '󰃬', hl = 'MiniIconsGrey' },
					copilot = { glyph = '', hl = 'MiniIconsGrey' },
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

			-- Hipatterns
			local hipatterns = require 'mini.hipatterns'
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

					local not_in_capture = vim.tbl_isempty(vim.tbl_filter(pred, captures))

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
						string.format('MiniHipatterns%s', hl:sub(1, 1):upper() .. hl:sub(2))
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

			-- Clue
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
					clue.gen_clues.builtin_completion(),
					clue.gen_clues.g(),
					clue.gen_clues.marks(),
					clue.gen_clues.registers(),
					clue.gen_clues.windows(),
					clue.gen_clues.z(),
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

			local sessions = require 'mini.sessions'

			sessions.setup {
				file = '',
			}

			local function get_session_name()
				local name = string.gsub(vim.fn.getcwd(), '/', '_')
				local obj = vim
					.system({ 'git', 'branch', '--show-current' }, { text = true })
					:wait()
				local branch = vim.trim(obj.stdout or '')
				if obj.code == 0 and branch ~= '' then
					return name .. '_' .. branch
				else
					return name
				end
			end

			if vim.fn.argc(-1) == 0 then
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
			end
		end,
	},
}
