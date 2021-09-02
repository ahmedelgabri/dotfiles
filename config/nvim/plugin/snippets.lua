-- let g:vsnip_filetypes['typescript.tsx'] = ['javascript']
-- let g:vsnip_filetypes['jinja'] = ['html', 'htmldjango']
-- let g:vsnip_filetypes['jinja2'] = ['html', 'htmldjango']
-- let g:vsnip_filetypes['html.twig'] = ['htmldjango']
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

local function replace_each(replacer)
  return function(args)
    local len = #args[1][1]
    return { replacer:rep(len) }
  end
end

ls.snippets = {
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
    s(
      { trig = 'bang', dscr = 'Shebang!' },
      t '#!/usr/bin/env ',
      c(1, {
        t 'sh',
        t 'zsh',
        t 'bash',
        t 'python',
        t 'node',
      }),
      i(0)
    ),
    s(
      { trig = 'todo' },
      t 'TODO: ${1:Do something} (${CURRENT_MONTH_NAME} ${CURRENT_DATE}, ${CURRENT_YEAR} ${CURRENT_HOUR}:${CURRENT_MINUTE}, ${2:${VIM:\\$GITHUB_USER}})\n$0'
    ),
    s(
      'trig',
      c(1, {
        t 'Ugh boring, a text node',
        i(nil, 'At least I can edit something now...'),
        f(function(args)
          return 'Still only counts as text!!'
        end, {}),
      })
    ),
    s({ trig = 'fn' }, {
      c(1, {
        t { 'public ' },
        t { 'private ' },
      }),
      c(2, {
        t { 'void' },
        i(nil, { '' }),
        t { 'String' },
        t { 'char' },
        t { 'int' },
        t { 'double' },
        t { 'boolean' },
      }),
      t { ' ' },
      i(3, { 'myFunc' }),
      t { '(' },
      i(4),
      t { ')' },
      c(5, {
        t { '' },
        sn(nil, {
          t { '', ' throws ' },
          i(1),
        }),
      }),
      t { ' {', '\t' },
      i(0),
      t { '', '}' },
    }),
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
    s(
      { trig = 'frontmatter', dscr = 'Document frontmatter' },
      { t { '---', 'tags: ' }, i(1, 'value'), t { '', '---', '' } }
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
  },
}

ls.config.set_config {
  updateevents = 'TextChanged,TextChangedI', -- default is InsertLeave
}

require('luasnip.loaders.from_vscode').lazy_load {
  path = {
    '~/.config/nvim/pack/packer/start/friendly-snippets/snippets',
    './vsnip',
  },
}
