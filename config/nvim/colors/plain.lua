-- Name:       My version of plain.nvim
-- Version:    0.1
-- Maintainer: ahmedelgabri
-- License:    The MIT License (MIT)
--
-- Based on
--
--   https://github.com/andreypopp/vim-colors-plain (MIT License)
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

-- Clear highlights and reset syntax.
vim.cmd.highlight 'clear'
if vim.fn.exists 'syntax_on' then
	vim.cmd.syntax 'reset'
end

-- Enable terminal true-color support.
vim.o.termguicolors = true

vim.g.colors_name = 'plain'

local function highlight(name, opts)
	vim.api.nvim_set_hl(0, name, opts)
end

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

local themes = {
	dark = {
		bg = nil,
		bg_subtle = light_black,
		bg_very_subtle = subtle_black,
		norm = lighter_gray,
		norm_subtle = light_gray,
		norm_very_subtle = medium_gray,
		visual = lighter_black,
		cursor_line = subtle_black,
		constant = light_blue,
		comment = light_gray,
		selection = dark_yellow,
		selection_fg = black,
		ok = light_green,
		-- warning = yellow,
		error = light_red,
		purple = light_purple,
		cyan = light_cyan,
		green = light_green,
		red = light_red,
		yellow = light_yellow,
		blue = light_blue,
	},
	light = {
		bg = white,
		bg_subtle = lighter_gray,
		bg_very_subtle = light_gray,
		norm = light_black,
		norm_subtle = lighter_black,
		norm_very_subtle = medium_gray,
		visual = light_blue,
		cursor_line = lightest_gray,
		constant = dark_blue,
		comment = light_gray,
		selection = light_yellow,
		selection_fg = light_black,
		ok = light_green,
		-- warning = yellow,
		error = dark_red,
		purple = dark_purple,
		cyan = dark_cyan,
		green = dark_green,
		red = dark_red,
		yellow = dark_yellow,
		blue = dark_blue,
	},
}

local colors = themes[vim.opt.background:get()] or themes.dark

-- __Normal__
highlight('Normal', { fg = colors.norm, bg = colors.bg })
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
highlight('VertSplit', { bg = nil, fg = colors.visual })

-- __Operator__
highlight('Noise', { fg = colors.norm_subtle })
highlight('Operator', { link = 'Noise' })
highlight('LineNr', { link = 'Noise' })
highlight('CursorLineNr', { link = 'LineNr' })
highlight('FoldColumn', { link = 'LineNr' })
highlight('SignColumn', { link = 'LineNr' })

-- __Comment__
highlight('Comment', { italic = true, bg = nil, fg = colors.bg_subtle })
highlight('LineNr', { bg = nil, fg = colors.bg_subtle })
highlight('Whitespace', { fg = colors.bg_very_subtle })
highlight('Todo', { link = 'Comment' })
highlight('Conceal', { link = 'NonText' })

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
highlight('StatusLine', { bg = nil, fg = colors.norm })

-- __StatusLineNC__
highlight(
	'StatusLineNC',
	{ italic = true, bg = nil, fg = colors.norm_very_subtle }
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
highlight('Pmenu', { fg = colors.cursor_line, bg = nil })
highlight('PmenuSbar', { link = 'Pmenu' })
highlight('PmenuThumb', { link = 'Pmenu' })
-- __PmenuSel__
highlight('PmenuSel', { fg = nil, bg = colors.lighter_gray, blend = 0 })

-- TabLine --
highlight('Tabline', { ctrem = nil, gui = nil })
highlight('TablineFill', { ctrem = nil, gui = nil })
highlight('TablineSel', { reverse = true })

-- Floating Window --
highlight('NormalFloat', { gui = nil, ctrem = nil, fg = colors.norm })
highlight('FloatBorder', { link = 'Number' })

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

highlight('graphqlString', { link = 'Comment' })

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

highlight('MutedImports', { bg = nil, fg = colors.bg })
highlight(
	'MutedImportsInfo',
	{ italic = true, bold = true, bg = nil, fg = colors.bg_subtle }
)

-- Startify
highlight('StartifyHeader', { link = 'Normal' })
highlight('StartifyFile', { link = 'Directory' })
highlight('StartifyPath', { link = 'LineNr' })
highlight('StartifySlash', { link = 'StartifyPath' })
highlight('StartifyBracket', { link = 'StartifyPath' })
highlight('StartifyNumber', { link = 'Title' })

-- NvimTree --
highlight('NvimTreeGitDirty', { link = 'DiffChange' })
highlight('NvimTreeGitStaged', { link = 'DiffChange' })
highlight('NvimTreeGitMerge', { link = 'DiffText' })
highlight('NvimTreeGitRenamed', { link = 'DiffChange' })
highlight('NvimTreeGitNew', { link = 'DiffAdd' })
highlight('NvimTreeGitDeleted', { link = 'DiffDelete' })

-- Mini --
highlight('MiniIndentscopeSymbol', { link = 'Comment' })
highlight('MiniIndentscopeSymbolOff', { link = 'MiniIndentscopeSymbol' })

-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#highlights
highlight('@annotation', { link = 'Cursor' })
highlight('@attribute', { link = 'Constant' })
highlight('@boolean', { link = 'Constant' })
highlight('@character', { link = 'Constant' })
highlight('@comment', { link = 'Comment' })
-- highlight('@comment.error', { link = 'Comment' })
-- highlight('@comment.note', { link = 'Comment' })
-- highlight('@comment.todo', { link = 'Comment' })
-- highlight('@comment.warning', { link = 'Comment' })
-- highlight('@comment.documentation', { link = 'Comment' })
highlight('@constant', { link = 'Constant' })
highlight('@constant.builtin', { link = 'Constant' })
highlight('@constant.macro', { link = 'PreProc' })
highlight('@constructor', { link = 'Normal' })
-- highlight('@diff.delta', { link = 'Normal' })
-- highlight('@diff.minus', { link = 'Normal' })
-- highlight('@diff.plus', { link = 'Normal' })
highlight('@error', { link = 'Error' })
highlight('@exception', { link = 'Error' })
highlight('@function', { link = 'Normal' })
highlight('@function.builtin', { link = 'Noise' })
highlight('@function.macro', { link = 'PreProc' })
highlight('@function.method', { link = 'Normal' })
highlight('@keyword', { link = 'Noise' })
highlight('@keyword.conditional', { link = 'Normal' })
highlight('@keyword.function', { link = 'Noise' })
highlight('@keyword.import', { link = 'Noise' })
highlight('@keyword.repeat', { link = 'Normal' })
highlight('@label', { link = 'Noise' })
highlight('@markup', { link = 'Normal' })
highlight('@markup.emphasis', { italic = true })
highlight('@markup.heading', { link = 'Title' })
highlight('@markup.link.url', { link = 'Constant' })
highlight('@markup.list', { link = 'Noise' })
highlight('@markup.quote', { link = 'Comment' })
highlight('@markup.raw', { link = 'Noise' })
highlight('@markup.strike', { strikethrough = true })
highlight('@markup.strong', { bold = true })
highlight('@markup.underline', { link = 'Underlined', underline = true })
highlight('@module', { link = 'Noise' })
highlight('@none', { link = 'Noise' })
highlight('@number', { link = 'Constant' })
highlight('@number.float', { link = 'Constant' })
highlight('@operator', { link = 'Normal' })
highlight('@property', { link = '@field' })
highlight('@punctuation.bracket', { link = 'Noise' })
highlight('@punctuation.delimiter', { link = 'Noise' })
highlight('@string', { link = 'Constant' })
highlight('@string.escape', { link = 'Normal' })
highlight('@string.regexp', { link = 'Normal' })
highlight('@string.special.url', { link = 'Constant' })
highlight('@tag', { link = 'Statement' })
highlight('@tag.delimiter', { link = 'Noise' })
highlight('@type', { link = 'Noise' })
highlight('@type.builtin', { link = '@type' })
highlight('@variable', { link = 'Normal' })
highlight('@variable.builtin', { link = 'Normal' })
highlight('@variable.member', { link = 'Normal' })
highlight('@variable.parameter', { link = 'Statement' })
highlight('@variable.parameter.reference', { link = 'Statement' }) -- ???

-- nvim-cmp menu
-- matched item (what you typed until present)
highlight('CmpItemAbbrMatch', { link = 'DiffAdd', bold = true, italic = true })

-- type of completion snippet, function, etc... can also be highlighted
-- separately if needed
highlight('CmpItemKind', { link = 'NonText' })

-- the source of the completion
highlight('CmpItemMenu', { link = 'NonText' })

-- uncompleted item that may be good for completion
highlight('CmpItemAbbr', { link = 'NonText' })

highlight('CmpItemAbbrDeprecated', { strikethrough = true })
highlight('CmpItemAbbrMatch', { bold = true })
highlight('CmpItemAbbrMatchFuzzy', { bold = true })
highlight('CmpItemMenu', { italic = true })

highlight('CmpItemKindField', { fg = light_red })
highlight('CmpItemKindProperty', { fg = light_red })
highlight('CmpItemKindEvent', { fg = light_red })

highlight('CmpItemKindText', { fg = light_green })
highlight('CmpItemKindEnum', { fg = light_green })
highlight('CmpItemKindKeyword', { fg = light_green })

highlight('CmpItemKindConstant', { fg = light_yellow })
highlight('CmpItemKindConstructor', { fg = light_yellow })
highlight('CmpItemKindReference', { fg = light_yellow })

highlight('CmpItemKindFunction', { fg = light_purple })
highlight('CmpItemKindStruct', { fg = light_purple })
highlight('CmpItemKindClass', { fg = light_purple })
highlight('CmpItemKindModule', { fg = light_purple })
highlight('CmpItemKindOperator', { fg = light_purple })

highlight('CmpItemKindVariable', { fg = medium_gray })
highlight('CmpItemKindFile', { fg = medium_gray })

highlight('CmpItemKindUnit', { fg = dark_yellow })
highlight('CmpItemKindSnippet', { fg = dark_yellow })
highlight('CmpItemKindFolder', { fg = dark_yellow })

highlight('CmpItemKindMethod', { fg = light_blue })
highlight('CmpItemKindValue', { fg = light_blue })
highlight('CmpItemKindEnumMember', { fg = light_blue })

highlight('CmpItemKindInterface', { fg = light_cyan })
highlight('CmpItemKindColor', { fg = light_cyan })
highlight('CmpItemKindTypeParameter', { fg = light_cyan })

-- Misc. mainly my custom stuff --
highlight(
	'OverLength',
	{ fg = nil, bg = colors.selection_fg, ctermbg = 234, ctermfg = nil }
)

-- LspDiagnostics --
highlight('LspDiagnosticsDefaultError', { link = 'DiffDelete' })
highlight('LspDiagnosticsDefaultWarning', { link = 'DiffChange' })
highlight('LspDiagnosticsDefaultHint', { link = 'NonText' })

-- User highlights --
highlight('User5', { fg = colors.red })
highlight('User7', { fg = colors.cyan })
highlight('User4', { bg = nil, fg = colors.norm_very_subtle })
