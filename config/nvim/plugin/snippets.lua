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
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

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

        return sn(nil, fmt('{} vim:ft={} {}', { str[1], i(1), str[2] or '' }))
      end, {}),
    }),
    ls.parser.parse_snippet(
      { trig = 'vimfold' },
      '${1:Fold title} {{{\n\t${0:${TM_SELECTED_TEXT}}\n}}}'
    ),
    s(
      'bang',
      fmt('#!/usr/bin/env {}{}', {
        c(1, {
          t 'sh',
          t 'zsh',
          t 'bash',
          t 'python',
          t 'node',
        }),
        i(0),
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
      { trig = 'foo' },
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
  javascript = {
    s({ trig = 'require', dscr = 'require statement' }, {
      t 'const ',
      i(1, 'ModuleName'),
      t " = require('",
      d(2, function(nodes)
        return sn(1, { i(1, nodes[1][1]) })
      end, {
        1,
      }),
      t "');",
    }),
    s({ trig = '**', dscr = 'docblock' }, {
      t { '/**', '' },
      f(function(args)
        local lines = vim.tbl_map(function(line)
          print(vim.inspect(line))
          return ' * ' .. vim.trim(line)
        end, args[1].env.TM_SELECTED_TEXT)
        if #lines == 0 then
          return ' * '
        else
          return lines
        end
      end, {}),
      i(1),
      t { '', ' */' },
    }),
  },
  markdown = {
    s({ trig = 'frontmatter', dscr = 'Document frontmatter' }, {
      t { '---', 'tags: ' },
      i(1, 'value'),
      t { '', '---', '' },
    }),
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
  },
  html = {
    s('script', {
      t '<script',
      c(1, {
        sn(nil, {
          t ' src="',
          i(1, 'path/to/file.js'),
          t '">',
        }),
        sn(nil, {
          t { '>', '\t' },
          i(1, '// code'),
          t { '', '' },
        }),
      }),
      i(0),
      t '</script>',
    }),
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

ls.config.set_config {
  history = true,
  enable_autosnippets = true,
  updateevents = 'TextChanged,TextChangedI', -- default is InsertLeave
}

require('luasnip.loaders.from_vscode').lazy_load {
  path = {
    '~/.config/nvim/pack/packer/start/friendly-snippets/snippets',
    './vsnip',
  },
}
