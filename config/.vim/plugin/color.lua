local au = require '_.utils.au'

au.augroup('__MyCustomColors__', function()
  ---------------------------------------------------------------
  -- GENERAL
  ---------------------------------------------------------------
  au.autocmd('ColorScheme', '*', 'hi! clear SignColumn')
  au.autocmd('ColorScheme', '*', 'hi! Tabline cterm=NONE gui=NONE')
  au.autocmd('ColorScheme', '*', 'hi! TablineFill cterm=NONE gui=NONE')
  au.autocmd('ColorScheme', '*', 'hi! TablineSel cterm=reverse gui=reverse')
  au.autocmd('ColorScheme', '*', 'hi! NonText ctermbg=NONE guibg=NONE')
  au.autocmd(
    'ColorScheme',
    '*',
    [[if &background ==# 'dark' | hi! VertSplit gui=NONE guibg=NONE guifg=#333333 cterm=NONE ctermbg=NONE ctermfg=14 | endif]]
  )
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! OverLength guibg=%s ctermbg=%s guifg=NONE ctermfg=NONE', '#222222', '234'))]]
  )
  au.autocmd(
    'ColorScheme',
    '*',
    'hi! link LspDiagnosticsDefaultError DiffDelete'
  )
  au.autocmd(
    'ColorScheme',
    '*',
    'hi! link LspDiagnosticsDefaultWarning DiffChange'
  )
  au.autocmd('ColorScheme', '*', 'hi! link LspDiagnosticsDefaultHint NonText')
  au.autocmd('ColorScheme', '*', 'hi! User5 ctermfg=red guifg=red')
  au.autocmd('ColorScheme', '*', 'hi! User7 ctermfg=cyan guifg=cyan')
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('NonText', 'fg', 'gui'), utils#get_color('NonText','fg', 'cterm')))]]
  )
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Identifier', 'fg', 'gui'), utils#get_color('Identifier', 'fg', 'cterm')))]]
  )
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('NonText', 'fg', 'gui'), utils#get_color('NonText', 'fg', 'cterm')))]]
  )
  au.autocmd('ColorScheme', '*', 'highlight PmenuSel blend=0')
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! MutedImports gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Ignore', 'fg', 'gui'), utils#get_color('Ignore', 'fg', 'cterm')))]]
  )
  au.autocmd(
    'ColorScheme',
    '*',
    [[execute(printf('hi! MutedImportsInfo gui=italic,bold cterm=italic,bold guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('Comment', 'fg', 'gui'), utils#get_color('Comment', 'fg', 'cterm')))]]
  )

  ---------------------------------------------------------------
  -- CODEDARK & PLAIN
  ---------------------------------------------------------------
  au.autocmd('ColorScheme', 'codedark,plain', 'hi! link StartifyHeader Normal')
  au.autocmd('ColorScheme', 'codedark,plain', 'hi! link StartifyFile Directory')
  au.autocmd('ColorScheme', 'codedark,plain', 'hi! link StartifyPath LineNr')
  au.autocmd(
    'ColorScheme',
    'codedark,plain',
    'hi! link StartifySlash StartifyPath'
  )
  au.autocmd(
    'ColorScheme',
    'codedark,plain',
    'hi! link StartifyBracket StartifyPath'
  )
  au.autocmd('ColorScheme', 'codedark,plain', 'hi! link StartifyNumber Title')

  ---------------------------------------------------------------
  -- PLAIN
  ---------------------------------------------------------------
  au.autocmd(
    'ColorScheme',
    'plain',
    [[execute(printf('hi! LineNr gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', utils#get_color('VisualNOS', 'bg', 'gui'), utils#get_color('VisualNOS', 'bg', 'cterm')))]]
  )
  au.autocmd(
    'ColorScheme',
    'plain',
    'hi! Comment cterm=italic gui=italic ctermfg=236 guifg=#555555'
  )
  au.autocmd(
    'ColorScheme',
    'plain',
    [[execute(printf('hi! Pmenu gui=NONE cterm=NONE guibg=#222222 ctermbg=234 guifg=%s ctermfg=%s', utils#get_color('Pmenu', 'fg', 'gui'), utils#get_color('Pmenu', 'fg', 'cterm')))]]
  )
  au.autocmd('ColorScheme', 'plain', 'hi! link PmenuSel TermCursor')
  au.autocmd('ColorScheme', 'plain', 'hi! Whitespace ctermfg=235 guifg=#333333')
  au.autocmd('ColorScheme', 'plain', 'hi! link graphqlString Comment')
  au.autocmd('ColorScheme', 'plain', 'hi! link Todo Comment')
  au.autocmd('ColorScheme', 'plain', 'hi! link Conceal NonText')
  au.autocmd('ColorScheme', 'plain', 'hi! link Error ErrorMsg')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapSelect CursorLine')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapMultiSelect DiffAdd')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapNormal Normal')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapBorder SnapNormal')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapPrompt NonText')
  au.autocmd('ColorScheme', 'plain', 'hi! link SnapPosition DiffText')

  ---------------------------------------------------------------
  -- MISC
  ---------------------------------------------------------------
  au.autocmd(
    'BufWinEnter,BufEnter',
    '?*',
    [[lua require'_.autocmds'.highlight_overlength()]]
  )
  au.autocmd(
    'BufWinEnter,BufEnter',
    '*',
    [[lua require'_.autocmds'.highlight_git_markers()]]
  )
  au.autocmd(
    'OptionSet',
    'textwidth',
    [[lua require'_.autocmds'.highlight_overlength()]]
  )
end)

-- Order is important, so autocmds above works properly
vim.opt.background = 'dark'
vim.cmd [[silent! colorscheme plain]]
