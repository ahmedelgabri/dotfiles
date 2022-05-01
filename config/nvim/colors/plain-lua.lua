-- Name:       plain.nvim
-- Version:    0.1
-- Maintainer: http//github.com/ahmedelgabri
-- License:    The MIT License (MIT)
--
-- Based on
--
--   http//github.com/ahmedelgabri/vim-colors-plain (MIT License)
--
-- Based on
--
--   http//github.com/pbrisbin/vim-colors-off (MIT License)
--
-- which in turn based on
--
--   http//github.com/reedes/vim-colors-pencil (MIT License)
--
--

vim.cmd [[
  highlight clear
  syntax reset
]]

vim.g.colors_name = 'plain-lua'

local black = '#222222'
local medium_gray = '#767676'
local white = '#F1F1F1'
local light_black = '#424242'
local lighter_black = '#545454'
local subtle_black = '#303030'
local light_gray = '#999999'
local lighter_gray = '#CCCCCC'
local lightest_gray = '#E5E5E5'
local dark_red = '#C30771'
local light_red = '#E32791'
local dark_blue = '#008EC4'
local light_blue = '#B6D6FD'
local dark_cyan = '#20A5BA'
local light_cyan = '#4FB8CC'
local dark_green = '#10A778'
local light_green = '#5FD7A7'
local dark_purple = '#523C79'
local light_purple = '#6855DE'
local light_yellow = '#F3E430'
local dark_yellow = '#A89C14'

local dark = {
  bg = black,
  bg_subtle = light_black,
  bg_very_subtle = subtle_black,
  norm = lighter_gray,
  norm_subtle = light_gray,
  norm_very_subtle = medium_gray,
  purple = light_purple,
  cyan = light_cyan,
  green = light_green,
  red = light_red,
  yellow = light_yellow,
  visual = lighter_black,
  cursor_line = subtle_black,
  constant = light_blue,
  comment = light_gray,
  selection = dark_yellow,
  selection_fg = black,
  ok = light_green,
  -- warning = yellow,
  error = light_red,
}

local light = {
  bg = white,
  bg_subtle = lighter_gray,
  bg_very_subtle = light_gray,
  norm = light_black,
  norm_subtle = lighter_black,
  norm_very_subtle = medium_gray,
  purple = dark_purple,
  cyan = dark_cyan,
  green = dark_green,
  red = dark_red,
  yellow = dark_yellow,
  visual = light_blue,
  cursor_line = lightest_gray,
  constant = dark_blue,
  comment = light_gray,
  selection = light_yellow,
  selection_fg = light_black,
  ok = light_green,
  -- warning = yellow,
  error = dark_red,
}

local function highlight(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

-- figure out why this is not working as I expect
-- local colors = vim.opt.background == 'dark' and dark or light
local colors = dark

-- __Normal__
highlight('Normal', { fg = colors.norm })
highlight('Cursor', { fg = colors.bg, bg = colors.norm })
highlight('Identifier', { link = 'Normal' })
highlight('Function', { link = 'Identifier' })
highlight('Type', { link = 'Normal' })
highlight('StorageClass', { link = 'Type' })
highlight('Structure', { link = 'Type' })
highlight('Typedef', { link = 'Type' })
highlight('Special', { link = 'Normal' })
highlight('SpecialChar', { link = 'Special' })
highlight('Tag', { link = 'Special' })
highlight('Delimiter', { link = 'Special' })
highlight('SpecialComment', { link = 'Special' })
highlight('Debug', { link = 'Special' })
highlight('VertSplit', { link = 'Normal' })
highlight('PreProc', { link = 'Normal' })
highlight('Define', { link = 'PreProc' })
highlight('Macro', { link = 'PreProc' })
highlight('PreCondit', { link = 'PreProc' })

-- __Operator__
highlight('Noise', { fg = colors.norm_subtle })
highlight('Operator', { link = 'Noise' })
highlight('LineNr', { link = 'Noise' })
highlight('CursorLineNr', { link = 'LineNr' })
highlight('FoldColumn', { link = 'LineNr' })
highlight('SignColumn', { link = 'LineNr' })

-- __Comment__
highlight('Comment', { fg = colors.comment, italic = true })

-- __Constant__
highlight('Constant', { fg = colors.constant })
highlight('Character', { link = 'Constant' })
highlight('Number', { link = 'Constant' })
highlight('Boolean', { link = 'Constant' })
highlight('Float', { link = 'Constant' })
highlight('String', { link = 'Constant' })
highlight('Directory', { link = 'Constant' })
highlight('Title', { link = 'Constant' })

-- __Statement__
highlight('Statement', { fg = colors.norm, bold = true })
highlight('Include', { link = 'Statement' })
highlight('Conditonal', { link = 'Statement' })
highlight('Repeat', { link = 'Statement' })
highlight('Label', { link = 'Statement' })
highlight('Keyword', { link = 'Statement' })
highlight('Exception', { link = 'Statement' })

-- __ErrorMsg__
highlight('ErrorMsg', { fg = colors.error })
highlight('Error', { link = 'ErrorMsg' })
highlight('Question', { link = 'ErrorMsg' })
-- __WarningMsg__
highlight('WarningMsg', { fg = colors.warning })
-- __MoreMsg__
highlight('MoreMsg', { fg = colors.norm_subtle, bold = true })
highlight('ModeMsg', { link = 'MoreMsg' })

-- __NonText__
highlight('NonText', { fg = colors.norm_very_subtle })
highlight('Folded', { link = 'NonText' })
highlight('qfLineNr', { link = 'NonText' })

-- __Search__
highlight('Search', { bg = colors.selection, fg = colors.selection_fg })
highlight(
  'IncSearch',
  { bg = colors.selection, fg = colors.selection_fg, bold = true }
)

-- __Visual__
highlight('Visual', { bg = colors.visual })
-- __VisualNOS__
highlight('VisualNOS', { bg = colors.bg_subtle })

highlight('Ignore', { fg = colors.bg })

-- __DiffAdd__
highlight('DiffAdd', { fg = colors.green })
-- __DiffDelete__
highlight('DiffDelete', { fg = colors.red })
-- __DiffChange__
highlight('DiffChange', { fg = colors.yellow })
-- __DiffText__
highlight('DiffText', { fg = colors.constant })

highlight('SpellBad', { underline = true, sp = colors.red })
highlight('SpellCap', { underline = true, sp = colors.ok })
highlight('SpellRare', { underline = true, sp = colors.error })
highlight('SpellLocal', { underline = true, sp = colors.ok })

highlight('helpHyperTextEntry', { link = 'Title' })
highlight('helpHyperTextJump', { link = 'String' })

-- __StatusLine__
highlight(
  'StatusLine',
  { underline = true, bg = colors.bg, fg = colors.norm_very_subtle }
)
-- __StatusLineNC__
highlight(
  'StatusLineNC',
  { underline = true, bg = colors.bg, fg = colors.bg_subtle }
)
-- __WildMenu__
highlight(
  'WildMenu',
  { underline = true, bold = true, bg = colors.bg, fg = colors.norm }
)

highlight('StatusLineOk', { underline = true, bg = colors.bg, fg = colors.ok })
highlight(
  'StatusLineError',
  { underline = true, bg = colors.bg, fg = colors.error }
)
highlight(
  'StatusLineWarning',
  { underline = true, bg = colors.bg, fg = colors.warning }
)

-- __Pmenu__
highlight('Pmenu', { fg = colors.norm, bg = colors.cursor_line })
highlight('PmenuSbar', { link = 'Pmenu' })
highlight('PmenuThumb', { link = 'Pmenu' })
-- __PmenuSel__
highlight(
  'PmenuSel',
  { fg = colors.norm, bg = colors.cursor_line, bold = true }
)

highlight('TabLine', { link = 'Normal' })
highlight('TabLineSel', { link = 'Keyword' })
highlight('TabLineFill', { link = 'Normal' })

-- __CursorLine__
highlight('CursorLine', { bg = colors.cursor_line })
-- __CursorColumn__
highlight('ColorColumn', { bg = colors.cursor_line })

-- __MatchParen__
highlight('MatchParen', { bg = colors.bg_subtle, fg = colors.norm })

highlight('htmlH1', { link = 'Normal' })
highlight('htmlH2', { link = 'Normal' })
highlight('htmlH3', { link = 'Normal' })
highlight('htmlH4', { link = 'Normal' })
highlight('htmlH5', { link = 'Normal' })
highlight('htmlH6', { link = 'Normal' })

highlight('diffRemoved', { link = 'DiffDelete' })
highlight('diffAdded', { link = 'DiffAdd' })

-- Signify, git-gutter
highlight('SignifySignAdd', { link = 'LineNr' })
highlight('SignifySignDelete', { link = 'LineNr' })
highlight('SignifySignChange', { link = 'LineNr' })
highlight('GitGutterAdd', { link = 'LineNr' })
highlight('GitGutterDelete', { link = 'LineNr' })
highlight('GitGutterChange', { link = 'LineNr' })
highlight('GitGutterChangeDelete', { link = 'LineNr' })

highlight('jsFlowTypeKeyword', { link = 'Statement' })
highlight('jsFlowImportType', { link = 'Statement' })
highlight('jsFunction', { link = 'Statement' })
highlight('jsGlobalObjects', { link = 'Normal' })
highlight('jsGlobalNodeObjects', { link = 'Normal' })
highlight('jsArrowFunction', { link = 'Noise' })
highlight('StorageClass', { link = 'Statement' })

highlight('xmlTag', { link = 'Constant' })
highlight('xmlTagName', { link = 'xmlTag' })
highlight('xmlEndTag', { link = 'xmlTag' })
highlight('xmlAttrib', { link = 'xmlTag' })

highlight('markdownH1', { link = 'Statement' })
highlight('markdownH2', { link = 'Statement' })
highlight('markdownH3', { link = 'Statement' })
highlight('markdownH4', { link = 'Statement' })
highlight('markdownH5', { link = 'Statement' })
highlight('markdownH6', { link = 'Statement' })
highlight('markdownListMarker', { link = 'Constant' })
highlight('markdownCode', { link = 'Constant' })
highlight('markdownCodeBlock', { link = 'Constant' })
highlight('markdownCodeDelimiter', { link = 'Constant' })
highlight('markdownHeadingDelimiter', { link = 'Constant' })

highlight('yamlBlockMappingKey', { link = 'Statement' })
highlight('pythonOperator', { link = 'Statement' })

highlight('ALEWarning', { link = 'WarningMsg' })
highlight('ALEWarningSign', { link = 'WarningMsg' })
highlight('ALEError', { link = 'ErrorMsg' })
highlight('ALEErrorSign', { link = 'ErrorMsg' })
highlight('ALEInfo', { link = 'InfoMsg' })
highlight('ALEInfoSign', { link = 'InfoMsg' })

highlight('sqlStatement', { link = 'Statement' })
highlight('sqlKeyword', { link = 'Keyword' })

-- unstable for now:
highlight('TSAnnotation', { link = 'Cursor' })
highlight('TSAttribute', { link = 'Cursor' })
highlight('TSBoolean', { link = 'Constant' })
highlight('TSCharacter', { link = 'Constant' })
highlight('TSComment', { link = 'Comment' })
highlight('TSConstructor', { link = 'Normal' })
highlight('TSConditional', { link = 'Normal' })
highlight('TSConstant', { link = 'Constant' })
highlight('TSConstBuiltin', { link = 'Cursor' })
highlight('TSConstMacro', { link = 'Cursor' })
highlight('TSError', { link = 'Error' })
highlight('TSException', { link = 'Error' })
highlight('TSField', { link = 'Normal' })
highlight('TSFloat', { link = 'Constant' })
highlight('TSFunction', { link = 'Normal' })
highlight('TSFuncBuiltin', { link = 'Noise' })
highlight('TSFuncMacro', { link = 'Cursor' })
highlight('TSInclude', { link = 'Noise' })
highlight('TSKeyword', { link = 'Noise' })
highlight('TSKeywordFunction', { link = 'Noise' })
highlight('TSLabel', { link = 'Noise' })
highlight('TSMethod', { link = 'Normal' })
highlight('TSNamespace', { link = 'Noise' })
highlight('TSNone', { link = 'Noise' })
highlight('TSNumber', { link = 'Constant' })
highlight('TSOperator', { link = 'Normal' })
highlight('TSParameter', { link = 'Statement' })
highlight('TSParameterReference', { link = 'Statement' })
highlight('TSProperty', { link = 'TSField' })
highlight('TSPunctDelimiter', { link = 'Noise' })
highlight('TSPunctBracket', { link = 'Noise' })
highlight('TSPunctSpecial', { link = 'Noise' })
highlight('TSRepeat', { link = 'Normal' })
highlight('TSString', { link = 'Constant' })
highlight('TSStringRegex', { link = 'Cursor' })
highlight('TSStringEscape', { link = 'Cursor' })
highlight('TSTag', { link = 'Statement' })
highlight('TSTagDelimiter', { link = 'Noise' })
highlight('TSText', { link = 'Normal' })
highlight('TSEmphasis', { link = 'Statement' })
highlight('TSUnderline', { link = 'Underlined' })
highlight('TSStrike', { link = 'Underlined' })
highlight('TSTitle', { link = 'Statement' })
highlight('TSLiteral', { link = 'Noise' })
highlight('TSURI', { link = 'Constant' })
highlight('TSType', { link = 'Cursor' })
highlight('TSTypeBuiltin', { link = 'Cursor' })
highlight('TSVariable', { link = 'Normal' })
highlight('TSVariableBuiltin', { link = 'Normal' })
