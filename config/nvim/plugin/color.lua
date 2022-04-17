local utils = require '_.utils'
local au = require '_.utils.au'
local cmds = require '_.autocmds'

au.augroup('__MyCustomColors__', {
  ---------------------------------------------------------------
  -- COMPLETION
  ---------------------------------------------------------------
  -- matched item (what you typed until present)
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link CmpItemAbbrMatch DiffChange',
  },
  -- fuzzy match for what you typed
  -- {event =  'ColorScheme', pattern = '*', command = 'hi! link CmpItemAbbrMatchFuzzy DiffDelete'},
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link CmpItemKind DiffText',
  },
  -- uncompleted item that may be good for completion
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link CmpItemAbbr Normal',
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
    command = 'hi! TablineSel cterm=reverse gui=reverse',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! NonText ctermbg=NONE guibg=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! NormalFloat guibg=NONE',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link FloatBorder Number',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = [[if &background ==# 'dark' | hi! VertSplit gui=NONE guibg=NONE guifg=#333333 cterm=NONE ctermbg=NONE ctermfg=14 | endif]],
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! OverLength guibg=%s ctermbg=%s guifg=NONE ctermfg=NONE',
          '#222222',
          '234'
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link LspDiagnosticsDefaultError DiffDelete',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link LspDiagnosticsDefaultWarning DiffChange',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link LspDiagnosticsDefaultHint NonText',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! User5 ctermfg=red guifg=red',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! User7 ctermfg=cyan guifg=cyan',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('NonText', 'fg', 'gui'),
          utils.get_color('NonText', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('Identifier', 'fg', 'gui'),
          utils.get_color('Identifier', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('NonText', 'fg', 'gui'),
          utils.get_color('NonText', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'highlight PmenuSel blend=0',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! MutedImports gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('Ignore', 'fg', 'gui'),
          utils.get_color('Ignore', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! MutedImportsInfo gui=italic,bold cterm=italic,bold guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('Comment', 'fg', 'gui'),
          utils.get_color('Comment', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitDirty DiffChange',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitStaged DiffChange',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitMerge DiffText',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitRenamed DiffChange',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitNew DiffAdd',
  },
  {
    event = 'ColorScheme',
    pattern = '*',
    command = 'hi! link NvimTreeGitDeleted DiffDelete',
  },

  ---------------------------------------------------------------
  -- CODEDARK & PLAIN
  ---------------------------------------------------------------
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifyHeader Normal',
  },
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifyFile Directory',
  },
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifyPath LineNr',
  },
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifySlash StartifyPath',
  },
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifyBracket StartifyPath',
  },
  {
    event = 'ColorScheme',
    pattern = 'codedark,plain',
    command = 'hi! link StartifyNumber Title',
  },

  ---------------------------------------------------------------
  -- PLAIN
  ---------------------------------------------------------------
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! LineNr gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s',
          utils.get_color('VisualNOS', 'bg', 'gui'),
          utils.get_color('VisualNOS', 'bg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! Comment cterm=italic gui=italic ctermfg=236 guifg=#555555',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    callback = function()
      vim.fn.execute(
        string.format(
          'hi! Pmenu gui=NONE cterm=NONE guibg=#222222 ctermbg=234 guifg=%s ctermfg=%s',
          utils.get_color('Pmenu', 'fg', 'gui'),
          utils.get_color('Pmenu', 'fg', 'cterm')
        )
      )
    end,
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link PmenuSel ColorColumn',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! Whitespace ctermfg=235 guifg=#333333',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link graphqlString Comment',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link Todo Comment',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link Conceal NonText',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link Error ErrorMsg',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapSelect CursorLine',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapMultiSelect DiffAdd',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapNormal Normal',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapBorder SnapNormal',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapPrompt NonText',
  },
  {
    event = 'ColorScheme',
    pattern = 'plain',
    command = 'hi! link SnapPosition DiffText',
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
