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

-- Pull a color from Neovim's default palette so we track upstream changes
-- across versions. Capture BEFORE `highlight 'clear'` (below) wipes the named
-- groups. Hardcoded hex fallback covers older Neovim or odd load orders.
local function nvim_color(name, fallback)
	local hl = vim.api.nvim_get_hl(0, { name = name })
	if hl and hl.fg then
		return string.format('#%06X', hl.fg)
	end
	return fallback
end

-- See :help nvim-color-palette
local dark_red = nvim_color('NvimDarkRed', '#590008')
local light_red = nvim_color('NvimLightRed', '#FFC0B9')
local dark_blue = nvim_color('NvimDarkBlue', '#00378F')
local light_blue = nvim_color('NvimLightBlue', '#A6DBFF')
local dark_cyan = nvim_color('NvimDarkCyan', '#007373')
local light_cyan = nvim_color('NvimLightCyan', '#8CF8F7')
local dark_green = nvim_color('NvimDarkGreen', '#005523')
local light_green = nvim_color('NvimLightGreen', '#B3F6C0')
local dark_purple = nvim_color('NvimDarkMagenta', '#470045')
local light_purple = nvim_color('NvimLightMagenta', '#FFCAFF')
local light_yellow = nvim_color('NvimLightYellow', '#FCE094')
local dark_yellow = nvim_color('NvimDarkYellow', '#6B5300')

-- Clear highlights and reset syntax.
vim.cmd.highlight 'clear'
if vim.fn.exists 'syntax_on' then
	vim.cmd.syntax 'reset'
end

-- Enable terminal true-color support.
vim.o.termguicolors = true

vim.g.colors_name = 'plain'

local function highlight(name, opts)
	-- Force links
	opts.force = true
	vim.api.nvim_set_hl(0, name, opts)
end

local black = '#222222'
local medium_gray = '#767676'
local white = '#F1F1F1'
local light_black = '#424242'
local lighter_black = '#545454'
local subtle_black = '#191919'
local light_gray = '#999999'
local lighter_gray = '#CCCCCC'
local lightest_gray = '#E5E5E5'

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
		selection = light_yellow,
		selection_fg = black,
		ok = dark_green,
		warning = dark_yellow,
		error = light_red,
		purple = light_purple,
		cyan = light_cyan,
		green = light_green,
		red = light_red,
		yellow = light_yellow,
		blue = light_blue,
		diff_add_bg = dark_green,
		diff_delete_bg = dark_red,
		diff_change_bg = dark_yellow,
	},
	light = {
		bg = white,
		bg_subtle = lighter_gray,
		bg_very_subtle = light_gray,
		norm = light_black,
		norm_subtle = lighter_black,
		norm_very_subtle = medium_gray,
		visual = lighter_gray,
		cursor_line = lightest_gray,
		constant = dark_blue,
		comment = light_gray,
		selection = light_yellow,
		selection_fg = light_black,
		ok = light_green,
		warning = light_yellow,
		error = dark_red,
		purple = dark_purple,
		cyan = dark_cyan,
		green = dark_green,
		red = dark_red,
		yellow = dark_yellow,
		blue = dark_blue,
		diff_add_bg = light_green,
		diff_delete_bg = light_red,
		diff_change_bg = light_yellow,
	},
}

local colors = themes[vim.o.background] or themes.dark

-- __Normal__
highlight('Normal', { fg = colors.norm, bg = colors.bg })
highlight('Cursor', { fg = colors.bg, bg = colors.norm })
highlight('Identifier', { link = 'Normal' })
highlight('Function', { link = 'Identifier' })
highlight('Type', { link = 'Normal' })
highlight('Structure', { link = 'Type' })
highlight('Typedef', { link = 'Type' })
highlight('Special', { link = 'Normal' })
highlight('SpecialChar', { link = 'Special' })
highlight('Tag', { link = 'Special' })
highlight('Delimiter', { link = 'Special' })
highlight('SpecialComment', { link = 'Special' })
highlight('Debug', { link = 'Special' })
highlight('PreProc', { link = 'Normal' })
highlight('Define', { link = 'PreProc' })
highlight('Macro', { link = 'PreProc' })
highlight('PreCondit', { link = 'PreProc' })
highlight('VertSplit', { bg = nil, fg = colors.visual })
highlight('WinSeparator', { link = 'VertSplit' })
highlight('SpecialKey', { fg = colors.cyan })

-- __Operator__
highlight('Noise', { fg = colors.norm_subtle })
highlight('Operator', { link = 'Noise' })
highlight('FoldColumn', { link = 'LineNr' })
highlight('SignColumn', { link = 'LineNr' })

-- __Comment__
highlight('Comment', { italic = true, bg = nil, fg = colors.bg_subtle })
highlight('LineNr', { bg = nil, fg = colors.bg_subtle })
highlight('CursorLineNr', { link = 'LineNr' })
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
highlight('Conditional', { link = 'Statement' })
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
highlight('DiffAdd', { fg = colors.green, bg = colors.diff_add_bg })
-- __DiffDelete__
highlight('DiffDelete', { fg = colors.red, bg = colors.diff_delete_bg })
-- __DiffChange__
highlight('DiffChange', { fg = colors.yellow, bg = colors.diff_change_bg })
-- __DiffText__
highlight('DiffText', { fg = colors.constant })
highlight('DiffTextAdd', { link = 'DiffAdd' })

highlight('SpellBad', { underline = true, sp = colors.red })
highlight('SpellCap', { underline = true, sp = colors.ok })
highlight('SpellRare', { underline = true, sp = colors.error })
highlight('SpellLocal', { underline = true, sp = colors.ok })

highlight('helpHyperTextEntry', { link = 'Title' })
highlight('helpHyperTextJump', { link = 'String' })

-- __StatusLine__
highlight('StatusLine', { link = 'LineNr' })

-- __StatusLineNC__
highlight('StatusLineNC', { italic = true, bg = nil, fg = colors.bg_subtle })

-- __WildMenu__
highlight(
	'WildMenu',
	{ underline = true, bold = true, bg = colors.bg, fg = colors.norm }
)

highlight('StatusLineOk', { underline = true, bg = colors.bg, fg = colors.ok })
highlight('StatusLineModified', { fg = colors.yellow })
highlight('StatusLineDiffAdd', { fg = colors.green })
highlight('StatusLineDiffChange', { fg = colors.yellow })
highlight('StatusLineDiffDelete', { fg = colors.red })
highlight(
	'StatusLineError',
	{ underline = true, bg = colors.bg, fg = colors.error }
)
highlight(
	'StatusLineWarning',
	{ underline = true, bg = colors.bg, fg = colors.warning }
)
highlight('OkMsg', { link = 'StatusLineOk' })
highlight('StdoutMsg', { link = 'MoreMsg' })
highlight('StderrMsg', { link = 'ErrorMsg' })

-- __Pmenu__
highlight('Pmenu', { fg = colors.bg_subtle, bg = nil })
highlight('PmenuBorder', { link = 'FloatBorder' })
highlight('PmenuShadow', { bg = colors.bg_very_subtle })
highlight('PmenuShadowThrough', { bg = colors.bg_very_subtle })
highlight('PmenuSbar', { link = 'Pmenu' })
highlight('PmenuThumb', { link = 'Pmenu' })
-- __PmenuSel__
highlight('PmenuSel', { fg = colors.norm, bg = colors.bg_subtle })

-- TabLine --
highlight('TabLine', {})
highlight('TabLineFill', {})
highlight('TabLineSel', { reverse = true })

-- Floating Window --
highlight('NormalFloat', { fg = colors.norm, bg = nil })
highlight('FloatBorder', { link = 'Number' })

-- __CursorLine__
highlight('CursorLine', { bg = colors.cursor_line })
-- __CursorColumn__
highlight('ColorColumn', { bg = colors.bg_subtle })

-- __MatchParen__
highlight(
	'MatchParen',
	{ bg = colors.bg_subtle, fg = colors.norm, bold = true }
)

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

-- Mini --
highlight('MiniIndentscopeSymbol', { link = 'Comment' })
highlight('MiniIndentscopeSymbolOff', { link = 'MiniIndentscopeSymbol' })

highlight('MiniDiffSignAdd', { fg = colors.green })
highlight('MiniDiffSignChange', { fg = colors.yellow })
highlight('MiniDiffSignDelete', { fg = colors.red })
highlight('MiniDiffOverAdd', { link = 'DiffAdd' })
highlight('MiniDiffOverChange', { link = 'DiffChange' })
highlight('MiniDiffOverContext', { link = 'DiffText' })
highlight('MiniDiffOverDelete', { link = 'DiffDelete' })

highlight('MiniStarterCurrent', { link = 'Normal' })
highlight('MiniStarterInactive', { link = 'Comment' })
highlight('MiniStarterItem', { link = 'EndOfBuffer' })
highlight('MiniStarterItemBullet', { link = 'Comment' })
highlight('MiniStarterItemPrefix', { link = 'Normal' })
highlight('MiniStarterQuery', { fg = colors.red, bold = true })
highlight('MiniStarterDashboardHeader', { fg = colors.bg_subtle })
highlight('MiniStarterDashboardQuote', { link = 'Comment' })
highlight('MiniStarterDashboardAuthor', { fg = colors.bg_subtle })
highlight('MiniStarterDashboardDir', { link = 'Comment' })
highlight('MiniStarterDashboardFile', { link = 'Normal' })
highlight('MiniStarterDashboardIcon', { link = 'Normal' })
highlight('MiniStarterDashboardKey', { fg = colors.bg_subtle })
highlight('MiniStarterDashboardTitle', { fg = colors.norm_very_subtle })

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
highlight('@diff.delta', { link = 'DiffChange' })
highlight('@diff.minus', { link = 'DiffDelete' })
highlight('@diff.plus', { link = 'DiffAdd' })
highlight(
	'@diff.delta.diff',
	{ fg = colors.yellow, bg = colors.diff_change_bg }
)
highlight('@diff.minus.diff', { fg = colors.red, bg = colors.diff_delete_bg })
highlight('@diff.plus.diff', { fg = colors.green, bg = colors.diff_add_bg })
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
highlight('@markup.heading', { fg = colors.green, bold = true })
highlight('@markup.link.url', { link = 'Constant' })
highlight('@markup.link.label', { link = 'Constant' })
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

-- blink.cmp
highlight('BlinkCmpLabelDeprecated', { strikethrough = true })
highlight('BlinkCmpMenuSelection', { bg = colors.bg_subtle, fg = colors.norm })
highlight('BlinkCmpLabel', { link = 'NonText' })
highlight('BlinkCmpScrollBarThumb', { link = 'CursorLine' })
highlight(
	'BlinkCmpLabelMatch',
	{ fg = colors.green, bold = true, italic = true }
)
highlight('BlinkCmpKind', { link = 'NonText' })
highlight('BlinkCmpKindField', { fg = colors.red })
highlight('BlinkCmpKindProperty', { link = 'BlinkCmpKindField' })
highlight('BlinkCmpKindEvent', { link = 'BlinkCmpKindField' })
highlight('BlinkCmpKindText', { fg = colors.green })
highlight('BlinkCmpKindEnum', { link = 'BlinkCmpKindText' })
highlight('BlinkCmpKindKeyword', { link = 'BlinkCmpKindText' })
highlight('BlinkCmpKindConstant', { fg = colors.yellow })
highlight('BlinkCmpKindConstructor', { link = 'BlinkCmpKindConstant' })
highlight('BlinkCmpKindReference', { link = 'BlinkCmpKindConstant' })
highlight('BlinkCmpKindFunction', { fg = colors.purple })
highlight('BlinkCmpKindStruct', { link = 'BlinkCmpKindFunction' })
highlight('BlinkCmpKindClass', { link = 'BlinkCmpKindFunction' })
highlight('BlinkCmpKindModule', { link = 'BlinkCmpKindFunction' })
highlight('BlinkCmpKindOperator', { link = 'BlinkCmpKindFunction' })
highlight('BlinkCmpKindVariable', { fg = colors.blue })
highlight('BlinkCmpKindFile', { link = 'BlinkCmpKindVariable' })
highlight('BlinkCmpKindUnit', { fg = colors.yellow })
highlight('BlinkCmpKindSnippet', { link = 'BlinkCmpKindUnit' })
highlight('BlinkCmpKindFolder', { link = 'BlinkCmpKindUnit' })
highlight('BlinkCmpKindMethod', { fg = colors.blue })
highlight('BlinkCmpKindValue', { link = 'BlinkCmpKindMethod' })
highlight('BlinkCmpKindEnumMember', { link = 'BlinkCmpKindMethod' })
highlight('BlinkCmpKindInterface', { fg = colors.cyan })
highlight('BlinkCmpKindColor', { link = 'BlinkCmpKindInterface' })
highlight('BlinkCmpKindTypeParameter', { link = 'BlinkCmpKindInterface' })

-- Misc. mainly my custom stuff --
highlight(
	'OverLength',
	{ fg = nil, bg = colors.selection_fg, ctermbg = 234, ctermfg = nil }
)

-- Diagnostics (Neovim 0.6+) --
highlight('DiagnosticError', { link = 'ErrorMsg' })
highlight('DiagnosticWarn', { link = 'WarningMsg' })
highlight('DiagnosticInfo', { fg = colors.blue })
highlight('DiagnosticHint', { link = 'NonText' })
highlight('DiagnosticOk', { fg = colors.ok })

highlight('DiagnosticSignError', { link = 'DiagnosticError' })
highlight('DiagnosticSignWarn', { link = 'DiagnosticWarn' })
highlight('DiagnosticSignInfo', { link = 'DiagnosticInfo' })
highlight('DiagnosticSignHint', { link = 'DiagnosticHint' })
highlight('DiagnosticSignOk', { link = 'DiagnosticOk' })

highlight('DiagnosticVirtualTextError', { link = 'DiagnosticError' })
highlight('DiagnosticVirtualTextWarn', { link = 'DiagnosticWarn' })
highlight('DiagnosticVirtualTextInfo', { link = 'DiagnosticInfo' })
highlight('DiagnosticVirtualTextHint', { link = 'DiagnosticHint' })

highlight('DiagnosticUnderlineError', { underline = true, sp = colors.red })
highlight('DiagnosticUnderlineWarn', { underline = true, sp = colors.yellow })
highlight('DiagnosticUnderlineInfo', { underline = true, sp = colors.blue })
highlight('DiagnosticUnderlineHint', { underline = true, sp = colors.norm_very_subtle })

-- Lsp --
highlight('LspInlayHint', { fg = lighter_black, bg = nil, italic = true })
highlight('LspCodeLens', { link = 'Comment' })
highlight('LspCodeLensSeparator', { link = 'LspCodeLens' })
highlight('LspReferenceRead', { link = 'SpecialKey' })
highlight('LspReferenceText', { link = 'SpecialKey' })
highlight('LspReferenceWrite', { link = 'SpecialKey' })
highlight('LspReferenceTarget', { link = 'SpecialKey' })
highlight('SnippetTabstopActive', { link = 'Visual' })

-- User highlights --
highlight('User5', { fg = colors.red })
highlight('User6', { fg = colors.norm })
highlight('User7', { fg = colors.cyan })
highlight('User4', { bg = nil, fg = colors.norm_very_subtle })

-- Winbar
highlight('WinBar', { bg = nil, fg = '#9B9EA4' })
highlight('WinBarNC', { link = 'WinBar' })

-- FzfLua
highlight('FzfLuaBorder', { link = 'Comment' })

-- Render Markdown
highlight('RenderMarkdownCode', { bg = colors.bg_very_subtle })
highlight('RenderMarkdownH1Bg', { bg = nil })
highlight('RenderMarkdownH2Bg', { bg = nil })
highlight('RenderMarkdownH3Bg', { bg = nil })
highlight('RenderMarkdownH4Bg', { bg = nil })
highlight('RenderMarkdownH5Bg', { bg = nil })
highlight('RenderMarkdownH6Bg', { bg = nil })

highlight('RenderMarkdownH1Bg_border', { link = 'RenderMarkdownH1Bg' })
highlight('RenderMarkdownH2Bg_border', { link = 'RenderMarkdownH2Bg' })
highlight('RenderMarkdownH3Bg_border', { link = 'RenderMarkdownH3Bg' })
highlight('RenderMarkdownH4Bg_border', { link = 'RenderMarkdownH4Bg' })
highlight('RenderMarkdownH5Bg_border', { link = 'RenderMarkdownH5Bg' })
highlight('RenderMarkdownH6Bg_border', { link = 'RenderMarkdownH6Bg' })

-- Snacks
highlight('SnacksIndent', { link = 'Comment' })
highlight('SnacksIndentChunk', { link = 'Comment' })
highlight('SnacksIndentScope', { link = 'Comment' })
highlight('SnacksPickerBorder', { link = 'Comment' })
highlight('SnacksPickerBoxBorder', { link = 'SnacksPickerBorder' })
highlight('SnacksPickerInputBorder', { link = 'SnacksPickerBorder' })
highlight('SnacksPickerListBorder', { link = 'SnacksPickerBorder' })
highlight('SnacksPickerListCursorLine', { link = 'CursorLine' })
highlight('SnacksPickerPreviewBorder', { link = 'SnacksPickerBorder' })
highlight('SnacksPickerPrompt', { link = 'SnacksPickerBorder' })
highlight('SnacksPickerMatch', { fg = colors.blue, italic = true })
highlight('SnacksPickerDir', { link = 'Comment' })
highlight('SnacksPickerTotals', { link = 'Comment' })

-- Diffview
highlight('DiffviewDiffAdd', {
	fg = colors.green,
})
highlight('DiffviewDiffChange', {
	fg = colors.yellow,
})
highlight('DiffviewDiffDelete', {
	fg = colors.red,
})
highlight('DiffviewDiffAddAsDelete', { link = 'DiffviewDiffDelete' })
highlight('DiffviewDiffDeleteDim', { link = 'Comment' })
highlight('DiffviewDiffText', { link = 'DiffText' })

-- conflict-marker.nvim
highlight('ConflictOursMarker', { bg = '#2e5049' })
highlight('ConflictOurs', { link = 'ConflictOursMarker' })
highlight('ConflictTheirsMarker', { bg = '#344f69' })
highlight('ConflictTheirs', { link = 'ConflictTheirsMarker' })
highlight('ConflictMid', { bg = '#2f7366' })
highlight('ConflictBaseMarker', { bg = '#754a81' })
highlight('ConflictBase', { link = 'ConflictBaseMarker' })

highlight('RainbowDelimiterRed', { fg = lighter_gray })
highlight('RainbowDelimiterYellow', { fg = light_gray })
highlight('RainbowDelimiterBlue', { fg = medium_gray })
highlight('RainbowDelimiterOrange', { fg = lighter_black })
highlight('RainbowDelimiterGreen', { fg = light_black })
highlight('RainbowDelimiterViolet', { fg = subtle_black })
highlight('RainbowDelimiterCyan', { fg = subtle_black })

highlight('BlinkIndentScope', { link = 'MiniIndentscopeSymbol' })
