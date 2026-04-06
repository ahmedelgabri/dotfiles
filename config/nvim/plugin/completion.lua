-- Completion and snippets

Pack.add {
	{ src = 'https://github.com/rafamadriz/friendly-snippets' },
	{
		src = 'https://github.com/L3MON4D3/LuaSnip',
		data = {
			run = function(plugin)
				vim.fn.system { 'make', '-C', plugin.path, 'install_jsregexp' }
			end,
		},
	},
	{ src = 'https://github.com/moyiz/blink-emoji.nvim' },
	{ src = 'https://github.com/xzbdmw/colorful-menu.nvim' },
	{
		src = 'https://github.com/Saghen/blink.cmp',
		name = 'blink.cmp',
		version = vim.version.range '1.x',
	},
}

local utils = require '_.utils'

local has_words_before = function()
	if vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'prompt' then
		return false
	end
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0
		and vim.api
				.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]
				:match '^%s*$'
			== nil
end

local function get_mini_icon_info(ctx)
	local MiniIcons = require 'mini.icons'
	local source = ctx.item.source_name
	local label = ctx.item.label

	if source == nil then
		return
	end

	if source == 'path' then
		if label:match '%.[^/]+$' then
			return MiniIcons.get('file', label)
		end

		return MiniIcons.get('directory', ctx.item.label)
	end

	return MiniIcons.get('lsp', ctx.kind)
end

local function get_icon(ctx)
	local icon = get_mini_icon_info(ctx)

	return icon or ctx.kind_icon
end

local function get_icon_highlight(ctx)
	local _, hl, _ = get_mini_icon_info(ctx)

	return hl
end


local snippets_ready = false
local completion_ready = false

-- Setup toggle choice (works before plugin loads, guarded by choice_active check)
vim.keymap.set({ 'i', 's' }, '<C-l>', function()
	local ok, ls = pcall(require, 'luasnip')
	if ok and ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

local function ensure_snippets()
	if snippets_ready then
		return true
	end

	if not Pack.load { 'friendly-snippets', 'LuaSnip' } then
		return false
	end

	local ls = require 'luasnip'

	local s = ls.snippet
	local sn = ls.snippet_node
	local t = ls.text_node
	local i = ls.insert_node
	local f = ls.function_node
	local c = ls.choice_node
	local d = ls.dynamic_node
	local r = ls.restore_node
	local fmt = require('luasnip.extras.fmt').fmt
	local rep = require('luasnip.extras').rep
	-- https://github.com/L3MON4D3/LuaSnip/blob/1dbafec2379bd836bd09c4659d4c6e1a70eb380e/Examples/snippets.lua#L356=
	local l = require('luasnip.extras').lambda
	local types = require 'luasnip.util.types'

	ls.config.set_config {
		history = true,
		enable_autosnippets = true,
		store_selection_keys = '<Tab>', -- needed for TM_SELECTED_TEXT
		updateevents = 'TextChanged,TextChangedI', -- default is InsertLeave
		ext_opts = {
			[types.choiceNode] = {
				active = {
					virt_text = { { '← Choice', 'Todo' } },
				},
			},
		},
	}

	require('luasnip.loaders.from_vscode').lazy_load {
		lazy_paths = {
			string.format(
				'%s/%s%s',
				vim.env.XDG_DATA_HOME,
				vim.fn.hostname(),
				'/snippets'
			),
		},
	}

	-- Get a list of  the property names given an `interface_declaration`
	-- treesitter *tsx* node.
	---@param id_node {} Stands for "interface declaration node"
	---@return string[]
	local function get_prop_names(id_node)
		local object_type_node = id_node:child(2)
		if object_type_node:type() ~= 'object_type' then
			return {}
		end

		local prop_names = {}

		for prop_signature in object_type_node:iter_children() do
			if prop_signature:type() == 'property_signature' then
				local prop_iden = prop_signature:child(0)
				local prop_name = vim.treesitter.get_node_text(prop_iden, 0)
				prop_names[#prop_names + 1] = prop_name
			end
		end

		return prop_names
	end

	local react = {
		s(
			{ trig = 'rcomp' },
			fmt(
				[[
{}interface {}Props {{
  {}
}}

{}function {}({{{}}}: {}Props) {{
  return {}
}}
]],
				{
					i(1, 'export '),
					-- Initialize component name to file name
					d(2, function(_, snip)
						return sn(nil, {
							i(
								1,
								vim.fn.substitute(snip.env.TM_FILENAME, '\\..*$', '', 'g')
							),
						})
					end, { 1 }),
					i(3, '// props'),
					rep(1),
					rep(2),
					f(function(_, snip, _)
						local pos_begin = snip.nodes[6].mark:pos_begin()
						local pos_end = snip.nodes[6].mark:pos_end()
						local parser = vim.treesitter.get_parser(0, 'tsx')
						if parser == nil then
							return ''
						end

						local tstree = parser:parse()
						if tstree[1] == nil then
							return ''
						end

						local node = tstree[1]:root():named_descendant_for_range(
							pos_begin[1],
							pos_begin[2],
							pos_end[1],
							pos_end[2]
						)

						while node ~= nil and node:type() ~= 'interface_declaration' do
							node = node:parent()
						end

						if node == nil then
							return ''
						end

						-- `node` is now surely of type "interface_declaration"
						local prop_names = get_prop_names(node)

						return table.concat(prop_names, ', ')
					end, { 3 }),
					rep(2),
					i(5, "'Hello World!'"),
				}
			)
		),
	}

	local js_ts = {
		s(
			{ trig = 'import', dscr = 'import statement' },
			fmt("import {} from '{}{}';", {
				i(1, 'name'),
				i(2),
				d(3, function(nodes)
					local text = nodes[1][1]
					local _, _, typish, target =
						text:find '^%s*(%a*)%s*{?%s*(%a+).*}?%s*$'
					if typish == 'type' and target then
						return sn(1, { i(1, target) })
					elseif typish and target then
						return sn(1, { i(1, typish .. target) })
					else
						return sn(1, { i(1, 'specifier') })
					end
				end, { 1 }),
			})
		),
		s(
			{ trig = 'require', dscr = 'require statement' },
			fmt("const {} = require('{}{}');", {
				i(1, 'name'),
				i(2),
				d(3, function(nodes)
					local text = nodes[1][1]
					return sn(1, { i(1, text) })
				end, { 1 }),
			})
		),
		s({ trig = '**', dscr = 'docblock' }, {
			t { '/**', '' },
			f(function(_args, snip)
				local lines = vim.tbl_map(function(line)
					return ' * ' .. vim.trim(line)
				end, snip.env.SELECT_RAW)
				if #lines == 0 then
					return ' * '
				else
					return lines
				end
			end, {}),
			i(1),
			t { '', ' */' },
		}),
	}

	local function replace_each(replacer)
		return function(args)
			local len = #args[1][1]
			return { replacer:rep(len) }
		end
	end

	local twig = { 'html', 'twig' }

	ls.filetype_extend('jinja', twig)
	ls.filetype_extend('jinja2', twig)
	ls.filetype_extend('html.twig', twig)

	ls.filetype_extend('typescriptreact', { 'html' })
	ls.filetype_extend('javascriptreact', { 'html' })

	ls.add_snippets(nil, {
		all = {
			s({ trig = 'bbox', wordTrig = true }, {
				t { '╔' },
				f(replace_each '═', { 1 }),
				t { '╗', '║' },
				i(1, { 'content' }),
				t { '║', '╚' },
				f(replace_each '═', { 1 }),
				t { '╝' },
				i(0),
			}),
			s({ trig = 'sbox', wordTrig = true }, {
				t { '*' },
				f(replace_each '-', { 1 }),
				t { '*', '|' },
				i(1, { 'content' }),
				t { '|', '*' },
				f(replace_each '-', { 1 }),
				t { '*' },
				i(0),
			}),
			s('modeline', {
				d(1, function()
					local str = vim.split(vim.bo.commentstring, '%s', true)

					return sn(
						nil,
						fmt('{commentStart} vim:ft={text} {commentEnd}{next}', {
							commentStart = str[1],
							text = i(1),
							commentEnd = str[2] or '',
							next = i(0),
						})
					)
				end, {}),
			}),
			ls.parser.parse_snippet(
				{ trig = 'vimfold' },
				'${1:Fold title} {{{\n\t${0:${TM_SELECTED_TEXT}}\n}}}'
			),
			s(
				'bang',
				fmt('#!/usr/bin/env {shell}{next}', {
					shell = c(1, {
						t 'sh',
						t 'zsh',
						t 'bash',
						t 'python',
						t 'node',
					}),
					next = i(0),
				})
			),
			ls.parser.parse_snippet(
				{ trig = 'tmux-start' },
				[[#!/usr/bin/env sh

local SESSION_NAME="${1}"

# session:n.n
#     |   | |
#     |   | |___ pane number
#     |   |
#     |   |___ window number
#     |
#     |_____ session name

tmux rename-window "\$SESSION_NAME"
tmux split-window -h
tmux new-window -n "\$EDITOR"

# LEFT
tmux send-keys -t"\$SESSION_NAME":1.1 '${2}' C-m

# RIGHT
tmux send-keys -t"\$SESSION_NAME":1.2 '${3}' C-m

# EDITOR
tmux select-window -t"\$SESSION_NAME":2
tmux send-keys -t"\$SESSION_NAME":2.1 "direnv reload && \$EDITOR" C-m

tmux select-window -t"\$SESSION_NAME":2.1
${0}]]
			),
			ls.parser.parse_snippet(
				{ trig = 'todo' },
				string.format(
					'TODO: ${1:Do something} (${$CURRENT_MONTH_NAME} ${$CURRENT_DATE}, ${$CURRENT_YEAR} ${$CURRENT_HOUR}:${$CURRENT_MINUTE}, ${2:%s})\n$0',
					vim.env.GITHUB_USER
				)
			),
			s({ trig = 'fn' }, {
				c(1, {
					t 'public ',
					t 'private ',
				}),
				c(2, {
					t 'void',
					i(nil, { '' }),
					t 'String',
					t 'char',
					t 'int',
					t 'double',
					t 'boolean',
				}),
				t ' ',
				i(3, { 'myFunc' }),
				t '(',
				i(4),
				t ')',
				c(5, {
					t '',
					sn(nil, {
						t { '', ' throws ' },
						i(1),
					}),
				}),
				t { ' {', '\t' },
				i(0),
				t { '', '}' },
			}),
			ls.parser.parse_snippet(
				{ trig = 'dumpenv' },
				[[
  ${$TM_SELECTED_TEXT} --  TM_SELECTED_TEXT The currently selected text or the empty string
  ${$TM_CURRENT_LINE} --  TM_CURRENT_LINE The contents of the current line
  ${$TM_CURRENT_WORD} --  TM_CURRENT_WORD The contents of the word under cursor or the empty string
  ${$TM_LINE_INDEX} --  TM_LINE_INDEX The zero-index based line number
  ${$TM_LINE_NUMBER} --  TM_LINE_NUMBER The one-index based line number
  ${$TM_FILENAME} --  TM_FILENAME The filename of the current document
  ${$TM_FILENAME_BASE} --  TM_FILENAME_BASE The filename of the current document without its extensions
  ${$TM_DIRECTORY} --  TM_DIRECTORY The directory of the current document
  ${$TM_FILEPATH} --  TM_FILEPATH The full file path of the current document
  ${$RELATIVE_FILEPATH} --  RELATIVE_FILEPATH The relative (to the opened workspace or folder) file path of the current document
  ${$CLIPBOARD} --  CLIPBOARD The contents of your clipboard
  ${$WORKSPACE_NAME} --  WORKSPACE_NAME The name of the opened workspace or folder
  ${$WORKSPACE_FOLDER} --  WORKSPACE_FOLDER The path of the opened workspace or folder
  ${$CURRENT_YEAR} --  CURRENT_YEAR The current year
  ${$CURRENT_YEAR_SHORT} --  CURRENT_YEAR_SHORT The current year's last two digits
  ${$CURRENT_MONTH} --  CURRENT_MONTH The month as two digits (example '02')
  ${$CURRENT_MONTH_NAME} --  CURRENT_MONTH_NAME The full name of the month (example 'July')
  ${$CURRENT_MONTH_NAME_SHORT} --  CURRENT_MONTH_NAME_SHORT The short name of the month (example 'Jul')
  ${$CURRENT_DATE} --  CURRENT_DATE The day of the month
  ${$CURRENT_DAY_NAME} --  CURRENT_DAY_NAME The name of day (example 'Monday')
  ${$CURRENT_DAY_NAME_SHORT} --  CURRENT_DAY_NAME_SHORT The short name of the day (example 'Mon')
  ${$CURRENT_HOUR} --  CURRENT_HOUR The current hour in 24-hour clock format
  ${$CURRENT_MINUTE} --  CURRENT_MINUTE The current minute
  ${$CURRENT_SECOND} --  CURRENT_SECOND The current second
  ${$CURRENT_SECONDS_UNIX} --  CURRENT_SECONDS_UNIX The number of seconds since the Unix epoch
  ${$RANDOM} --  RANDOM 6 random Base-10 digits
  ${$RANDOM_HEX} --  RANDOM_HEX 6 random Base-16 digits
  ${$UUID} --  UUID A Version 4 UUID
  ${$BLOCK_COMMENT_START} --  BLOCK_COMMENT_START Example output: in PHP /* or in HTML <!--
  ${$BLOCK_COMMENT_END} --  BLOCK_COMMENT_END Example output: in PHP */ or in HTML -->
  ${$LINE_COMMENT} --  LINE_COMMENT Example output: in PHP //
    ]]
			),
		},
		javascript = js_ts,
		typescript = js_ts,
		javascriptreact = vim.tbl_extend('force', {}, js_ts, react),
		typescriptreact = vim.tbl_extend('force', {}, js_ts, react),
		markdown = {
			ls.parser.parse_snippet(
				{ trig = 'fmatter', dscr = 'Document frontmatter' },
				[[
---
title: ${1:Title}
date: ${CURRENT_DATE}-${CURRENT_MONTH}-${CURRENT_YEAR}T${CURRENT_HOUR}:${CURRENT_MINUTE}
${3:tags}: $4
---

$0
]]
			),
			ls.parser.parse_snippet(
				{
					trig = 'oto',
					dscr = 'One to one section',
				},
				[=[## [[${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}]]
$0

### My topics

### Their topics

### Actions
]=]
			),
			s(
				{ trig = 'img', dscr = 'Markdown image' },
				fmt('![{alt}]({url}){next}', {
					url = f(function(_, snip)
						return snip.env.TM_SELECTED_TEXT[1]
							or sn(nil, i(1, 'https://example.com'))
					end, {}),
					alt = i(1, 'ALt'),
					next = i(0),
				})
			),
			s(
				{ trig = 'link', dscr = 'Markdown link' },
				fmt('[{text}]({url}){next}', {
					url = f(function(_, snip)
						return snip.env.TM_SELECTED_TEXT[1]
							or sn(nil, i(1, 'https://example.com'))
					end, {}),
					text = i(1, 'Text'),
					next = i(0),
				})
			),
			s({ trig = 'table', dscr = 'Table template' }, {
				t '| ',
				i(1, 'First Header'),
				t {
					'  | Second Header |',
					'| ------------- | ------------- |',
					'| Content Cell  | Content Cell  |',
					'| Content Cell  | Content Cell  |',
				},
			}),
			ls.parser.parse_snippet(
				{ trig = 'footer', dscr = 'Project footer' },
				[[
**${1:projectname}** © ${$CURRENT_YEAR}+, Ahmed El Gabri Released under the [MIT] License.<br>
Authored and maintained by Ahmed El Gabri with help from contributors ([list][contributors]).

> [https://gabri.me](https://gabri.me) &nbsp;&middot;&nbsp;
> GitHub [@ahmedelgabri](https://github.com/ahmedelgabri) &nbsp;&middot;&nbsp;
> Twitter [@ahmedelgabri](https://twitter.com/ahmedelgabri)

[MIT]: http://mit-license.org/
[contributors]: http://github.com/ahmedelgabri/$1/contributors
    ]]
			),
			ls.parser.parse_snippet(
				{ trig = 'mit', dscr = 'MIT Licence' },
				[[
The MIT License (MIT)

Copyright (c) ${$CURRENT_YEAR} ${0}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
    ]]
			),
		},
		html = {
			s(
				'script',
				fmt('<script {scriptEnd}{body}</script>{next}', {
					scriptEnd = c(1, {
						fmt('src="{src}">', {
							src = i(1, 'path/to/file.js'),
						}),
						fmt('>\n\t{code}\n\n', { code = i(1, '// code') }),
					}),
					body = i(2),
					next = i(0),
				})
			),
			s(
				{ trig = 'fav', dscr = 'Add an inline SVG Emoji Favicon' },
				fmt(
					'<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>{text}</text></svg>"/>',
					{ text = i(1) }
				)
			),
		},
		css = {
			s({
				trig = 'debug',
				dscr = 'Print box model from https://dev.to/gajus/my-favorite-css-hack-32g3',
			}, {
				t {
					'* { background-color: rgba(255,0,0,.2); }',
					'* * { background-color: rgba(0,255,0,.2); }',
					'* * * { background-color: rgba(0,0,255,.2); }',
					'* * * * { background-color: rgba(255,0,255,.2); }',
					'* * * * * { background-color: rgba(0,255,255,.2); }',
					'* * * * * * { background-color: rgba(255,255,0,.2); }',
					'* * * * * * * { background-color: rgba(255,0,0,.2); }',
					'* * * * * * * * { background-color: rgba(0,255,0,.2); }',
					'* * * * * * * * * { background-color: rgba(0,0,255,.2); }',
				},
			}),
		},
	})

	snippets_ready = true
	return true
end

local function ensure_completion()
	if completion_ready then
		return true
	end

	if not ensure_snippets() then
		return false
	end

	if not Pack.load { 'blink-emoji.nvim', 'colorful-menu.nvim', 'blink.cmp' } then
		return false
	end

	require('blink.cmp').setup {
		keymap = {
			-- Set my own, and get rid of the ones I don't use
			preset = 'none',
			['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
			['<C-c>'] = { 'hide' },

			['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
			['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

			['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
			['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

			-- Not sure about this one
			['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
			['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
			['<Tab>'] = {
				function(cmp)
					if not has_words_before() then
						return
					end

					if cmp.is_menu_visible() then
						return cmp.select_next()
					end
				end,
				'snippet_forward',
				'fallback',
			},
			['<CR>'] = { 'select_and_accept', 'fallback' },
		},

		snippets = { preset = 'luasnip' },

		completion = {
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},

			menu = {
				border = utils.get_border(),
				draw = {
					padding = 1,
					gap = 2,
					columns = { { 'kind_icon' }, { 'label', 'kind', gap = 2 } },
					components = {
						label = {
							width = { fill = true },
							text = function(ctx)
								return require('colorful-menu').blink_components_text(ctx)
							end,
							highlight = function(ctx)
								return require('colorful-menu').blink_components_highlight(
									ctx
								)
							end,
						},
						label_description = { width = { fill = true } },
						kind_icon = {
							text = get_icon,
							highlight = get_icon_highlight,
						},
						kind = {
							highlight = get_icon_highlight,
						},
					},
				},
			},

			documentation = {
				auto_show = true,
				treesitter_highlighting = true,
				window = {
					border = utils.get_border(),
				},
			},
			ghost_text = {
				enabled = true,
			},
		},

		-- Experimental signature help support
		signature = {
			enabled = true,
			window = {
				border = utils.get_border(),
				treesitter_highlighting = true,
			},
		},

		cmdline = { enabled = false },

		sources = {
			default = {
				'lsp',
				'path',
				'snippets',
				'buffer',
				'emoji',
			},
			providers = {
				lsp = {
					name = 'lsp',
					enabled = true,
					module = 'blink.cmp.sources.lsp',
					fallbacks = { 'buffer' },
				},
				path = {
					name = 'Path',
					module = 'blink.cmp.sources.path',
					fallbacks = { 'snippets', 'buffer' },
					opts = {
						trailing_slash = false,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
						end,
						show_hidden_files_by_default = true,
					},
				},
				buffer = {
					name = 'Buffer',
					enabled = true,
					max_items = 3,
					module = 'blink.cmp.sources.buffer',
					min_keyword_length = 4,
				},
				emoji = {
					module = 'blink-emoji',
					name = 'Emoji',
					opts = { insert = true },
				},
				snippets = {
					name = 'snippets',
					enabled = true,
					max_items = 8,
					min_keyword_length = 2,
					module = 'blink.cmp.sources.snippets',
				},
			},
		},
	}

	completion_ready = true
	return true
end

Pack.event('InsertEnter', {}, ensure_completion)
