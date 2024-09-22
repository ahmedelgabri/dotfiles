return {
	'https://github.com/L3MON4D3/LuaSnip',
	lazy = true,
	-- Build Step is needed for regex support in snippets
	build = 'make install_jsregexp',
	dependencies = {
		{ 'https://github.com/rafamadriz/friendly-snippets' },
	},
	config = function()
		local has_ls, ls = pcall(require, 'luasnip')

		if not has_ls then
			return
		end

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
				-- [types.insertNode] = {
				--   active = {
				--     virt_text = { { '← ...', 'Todo' } },
				--   },
				-- },
			},
		}

		require('luasnip.loaders.from_vscode').lazy_load {
			path = {
				string.format(
					'%s/pack/packer/start/friendly-snippets/snippets',
					vim.fn.stdpath 'data'
				),
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
		-- Ie, if the treesitter node represents:
		--   interface {
		--     prop1: string;
		--     prop2: number;
		--   }
		-- Then this function would return `{"prop1", "prop2"}
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
					local prop_name = vim.treesitter.query.get_node_text(prop_iden, 0)
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
							local tstree = parser:parse()

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
							fmt('src="{src}">', { src = i(1, 'path/to/file.js') }),
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
	end,
}
