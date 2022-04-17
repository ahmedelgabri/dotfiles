local utils = require '_.utils'
local au = require '_.utils.au'
local hl = require '_.utils.highlight'
local cmds = require '_.autocmds'

au.augroup('__MyCustomColors__', {
  ---------------------------------------------------------------
  -- COMPLETION
  ---------------------------------------------------------------
  -- matched item (what you typed until present)
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      print 'hi'
      hl.group('CmpItemAbbrMatch', { link = 'DiffChange' })
    end,
  },
  -- fuzzy match for what you typed
  -- {event =  'ColorScheme', pattern = '*', callback  = hl.group_cb('CmpItemAbbrMatchFuzzy', {link='DiffDelete'})},
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('CmpItemKind', { link = 'DiffText' })
    end,
  },
  -- uncompleted item that may be good for completion
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('CmpItemAbbr', { link = 'Normal' })
    end,
  },

  ---------------------------------------------------------------
  -- GENERAL
  ---------------------------------------------------------------
  { event = 'ColorScheme', pattern = '*', command = 'hi! clear SignColumn' },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! Tabline cterm=NONE gui=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! TablineFill cterm=NONE gui=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('TablineSel', { reverse = true })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! NonText cterm=NONE gui=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! NormalFloat cterm=NONE gui=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('FloatBorder', { link = 'Number' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      if vim.o.background == 'dark' then
        hl.group('VertSplit', {
          bg = nil,
          fg = '#333333',
          ctermbg = nil,
          ctermfg = 14,
        })
      end
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('OverLength', {
        fg = nil,
        bg = '#222222',
        ctermbg = 234,
        ctermfg = nil,
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('LspDiagnosticsDefaultError', { link = 'DiffDelete' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('LspDiagnosticsDefaultWarning', { link = 'DiffChange' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('LspDiagnosticsDefaultHint', { link = 'NonText' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('User5', {
        fg = 'red',
        ctermfg = 'red',
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('User7', {
        fg = 'cyan',
        ctermfg = 'cyan',
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('User4', {
        bg = nil,
        fg = utils.get_color('NonText', 'fg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('NonText', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('StatusLine', {
        bg = nil,
        fg = utils.get_color('Identifier', 'fg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('Identifier', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('StatusLineNC', {
        italic = true,
        bg = nil,
        fg = utils.get_color('NonText', 'fg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('NonText', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('PmenuSel', {
        blend = 0,
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('MutedImports', {
        bg = nil,
        fg = utils.get_color('Ignore', 'fg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('Ignore', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('MutedImportsInfo', {
        italic = true,
        bold = true,
        bg = nil,
        fg = utils.get_color('Comment', 'fg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('Comment', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitDirty', { link = 'DiffChange' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitStaged', { link = 'DiffChange' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitMerge', { link = 'DiffText' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitRenamed', { link = 'DiffChange' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitNew', { link = 'DiffAdd' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      hl.group('NvimTreeGitDeleted', { link = 'DiffDelete' })
    end,
  },

  ---------------------------------------------------------------
  -- CODEDARK & PLAIN
  ---------------------------------------------------------------
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifyHeader', { link = 'Normal' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifyFile', { link = 'Directory' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifyPath', { link = 'LineNr' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifySlash', { link = 'StartifyPath' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifyBracket', { link = 'StartifyPath' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = { 'codedark', 'plain' },
    callback = function()
      hl.group('StartifyNumber', { link = 'Title' })
    end,
  },

  ---------------------------------------------------------------
  -- PLAIN
  ---------------------------------------------------------------
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('LineNr', {
        bg = nil,
        fg = utils.get_color('VisualNOS', 'bg', 'gui'),
        ctermbg = nil,
        ctermfg = utils.get_color('VisualNOS', 'bg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Comment', {
        italic = true,
        bg = nil,
        fg = '#555555',
        ctermbg = nil,
        ctermfg = 236,
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Pmenu', {
        bg = '#222222',
        fg = utils.get_color('Pmenu', 'fg', 'gui'),
        ctermbg = 234,
        ctermfg = utils.get_color('Pmenu', 'fg', 'cterm'),
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('PmenuSel', { link = 'ColorColumn' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Whitespace', {
        fg = '#333333',
        ctermfg = 235,
      })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('graphqlString', { link = 'Comment' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Todo', { link = 'Comment' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Conceal', { link = 'NonText' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('Error', { link = 'ErrorMsg' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapSelect', { link = 'CursorLine' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapMultiSelect', { link = 'DiffAdd' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapNormal', { link = 'Normal' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapBorder', { link = 'SnapNormal' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapPrompt', { link = 'NonText' })
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      hl.group('SnapPosition', { link = 'DiffText' })
    end,
  },

  ---------------------------------------------------------------
  -- MISC
  ---------------------------------------------------------------
  {
    event = { 'BufWinEnter', 'BufEnter' },
    pattern = '?*',
    callback = cmds.highlight_overlength,
  },
  {
    event = 'OptionSet',
    pattern = 'textwidth',
    callback = cmds.highlight_overlength,
  },
  {
    event = { 'BufWinEnter', 'BufEnter' },
    pattern = '*',
    callback = cmds.highlight_git_markers,
  },
})

-- Order is important, so autocmds above works properly
vim.opt.background = 'dark'
vim.cmd [[silent! colorscheme plain]]
