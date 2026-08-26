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
	-- Force links
	opts.force = true
	vim.api.nvim_set_hl(0, name, opts)
end

-- Keep these accents in step with the terminal's plain-dark/plain-light ANSI
-- palettes. Structural shades remain editor-specific because they need more
-- levels than a terminal's 16 slots provide.
local themes = {
	dark = {
		bg = nil,
		bg_subtle = '#424242',
		bg_very_subtle = '#191919',
		norm = '#C5C8C6',
		norm_subtle = '#969896',
		norm_very_subtle = '#767676',
		visual = '#424242',
		cursor_line = '#191919',
		constant = '#81A2BE',
		comment = '#767676',
		selection = '#F0C674',
		selection_fg = '#111111',
		ok = '#B5BD68',
		warning = '#F0C674',
		error = '#CC6666',
		purple = '#B294BB',
		cyan = '#8ABEB7',
		green = '#B5BD68',
		red = '#CC6666',
		yellow = '#F0C674',
		blue = '#81A2BE',
		diff_add_bg = '#263326',
		diff_delete_bg = '#3A2426',
		diff_change_bg = '#3A321F',
		conflict_ours = '#2E5049',
		conflict_theirs = '#344F69',
		conflict_mid = '#2F7366',
		conflict_base = '#754A81',
	},
	light = {
		bg = '#FAFAFA',
		bg_subtle = '#D6D6D6',
		bg_very_subtle = '#EFEFEF',
		norm = '#4D4D4C',
		norm_subtle = '#696C77',
		norm_very_subtle = '#767676',
		visual = '#D6D6D6',
		cursor_line = '#EFEFEF',
		constant = '#4271AE',
		comment = '#767676',
		selection = '#E8D9A8',
		selection_fg = '#383A42',
		ok = '#5F7800',
		warning = '#9A6800',
		error = '#C82829',
		purple = '#8959A8',
		cyan = '#287F85',
		green = '#5F7800',
		red = '#C82829',
		yellow = '#9A6800',
		blue = '#4271AE',
		diff_add_bg = '#E5EED5',
		diff_delete_bg = '#F4DDDD',
		diff_change_bg = '#F5E9C8',
		conflict_ours = '#D9EEE8',
		conflict_theirs = '#DCE8F2',
		conflict_mid = '#CBE8E1',
		conflict_base = '#EADDEE',
	},
}

local colors = themes[vim.o.background] or themes.dark

-- Mirror the terminal's plain-dark/plain-light ANSI palettes so :terminal
-- matches the outer terminal instead of Nvim's built-in 16 colors. Same
-- values as config/ghostty/themes/plain-* and config/kitty/themes/plain-*.conf.
local terminal_palettes = {
	dark = {
		'#303030',
		'#cc6666',
		'#b5bd68',
		'#f0c674',
		'#81a2be',
		'#b294bb',
		'#8abeb7',
		'#c5c8c6',
		'#666666',
		'#f2777a',
		'#99cc99',
		'#ffcc66',
		'#6699cc',
		'#cc99cc',
		'#66cccc',
		'#ffffff',
	},
	light = {
		'#383a42',
		'#c82829',
		'#5f7800',
		'#9a6800',
		'#4271ae',
		'#8959a8',
		'#287f85',
		'#8e908c',
		'#767676',
		'#a82020',
		'#4f6b00',
		'#805900',
		'#315f9c',
		'#774394',
		'#176f76',
		'#4d4d4c',
	},
}

for i, hex in
	ipairs(terminal_palettes[vim.o.background] or terminal_palettes.dark)
do
	vim.g['terminal_color_' .. (i - 1)] = hex
end

-- __Normal__
highlight('Normal', { fg = colors.norm, bg = colors.bg })
-- Same cursor blue as the ghostty/kitty themes; the TUI propagates this
-- to the terminal cursor (OSC 12), so without it nvim repaints the
-- cursor gray.
highlight('Cursor', { fg = '#111111', bg = '#20bbfc' })
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
highlight('Comment', { italic = true, bg = nil, fg = colors.comment })
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
-- __WarningMsg__
highlight('WarningMsg', { fg = colors.warning })
-- __MoreMsg__
highlight('MoreMsg', { fg = colors.norm_subtle, bold = true })
highlight('ModeMsg', { link = 'MoreMsg' })
highlight('Question', { link = 'MoreMsg' })

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
-- Strike matches git/delta deletions; jj and tig cannot render it.
highlight(
	'DiffDelete',
	{ fg = colors.red, bg = colors.diff_delete_bg, strikethrough = true }
)
-- __DiffChange__
highlight('DiffChange', { fg = colors.yellow, bg = colors.diff_change_bg })
-- __DiffText__
highlight('DiffText', { fg = colors.constant })
highlight('DiffTextAdd', { link = 'DiffAdd' })

highlight('SpellBad', { underline = true, sp = colors.red })
highlight('SpellCap', { underline = true, sp = colors.warning })
highlight('SpellRare', { underline = true, sp = colors.purple })
highlight('SpellLocal', { underline = true, sp = colors.cyan })

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
highlight('FloatBorder', { link = 'Comment' })

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

highlight('sqlStatement', { link = 'Statement' })
highlight('sqlKeyword', { link = 'Keyword' })

-- Mini --
-- mini.hipatterns paints TODO/FIXME-style markers via extmarks, which sit
-- above any @comment.* treesitter highlight; keep both in the same muted
-- style so markers scan by weight only.
highlight('MiniHipatternsFixme', { link = '@comment.error' })
highlight('MiniHipatternsHack', { link = '@comment.warning' })
highlight('MiniHipatternsNote', { link = '@comment.note' })
highlight('MiniHipatternsTodo', { link = '@comment.todo' })

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
highlight('@annotation', { link = 'Noise' })
highlight('@attribute', { link = 'Constant' })
highlight('@boolean', { link = 'Constant' })
highlight('@character', { link = 'Constant' })
highlight('@comment', { link = 'Comment' })
-- TODO/FIXME-style markers are signals, so they get accent colors; defined
-- here (not inherited from Nvim defaults) so they track the plain palette
-- in both modes. MiniHipatterns* groups link here too.
highlight('@comment.error', { bold = true, italic = true, fg = colors.error })
highlight('@comment.note', { bold = true, italic = true, fg = colors.cyan })
highlight('@comment.todo', { bold = true, italic = true, fg = colors.blue })
highlight(
	'@comment.warning',
	{ bold = true, italic = true, fg = colors.warning }
)
highlight('@comment.documentation', { link = 'Comment' })
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
highlight('@diff.minus.diff', {
	fg = colors.red,
	bg = colors.diff_delete_bg,
	strikethrough = true,
})
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
highlight('@markup.underline', { underline = true })
highlight('@module', { link = 'Noise' })
highlight('@none', { link = 'Noise' })
highlight('@number', { link = 'Constant' })
highlight('@number.float', { link = 'Constant' })
highlight('@operator', { link = 'Normal' })
highlight('@property', { link = 'Normal' })
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
highlight(
	'DiagnosticUnderlineHint',
	{ underline = true, sp = colors.norm_very_subtle }
)

-- Lsp --
highlight(
	'LspInlayHint',
	{ fg = colors.norm_very_subtle, bg = nil, italic = true }
)
highlight('LspCodeLens', { link = 'Comment' })
highlight('LspCodeLensSeparator', { link = 'LspCodeLens' })
highlight('LspReferenceRead', { link = 'SpecialKey' })
highlight('LspReferenceText', { link = 'SpecialKey' })
highlight('LspReferenceWrite', { link = 'SpecialKey' })
highlight('LspReferenceTarget', { link = 'SpecialKey' })
highlight('SnippetTabstopActive', { link = 'Visual' })

-- User highlights --
highlight('User6', { fg = colors.norm })
highlight('User4', { bg = nil, fg = colors.norm_very_subtle })

-- Winbar
highlight('WinBar', { bg = nil, fg = colors.norm_subtle })
highlight('WinBarNC', { link = 'WinBar' })

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
	strikethrough = true,
})
highlight('DiffviewDiffAddAsDelete', { link = 'DiffviewDiffDelete' })
highlight('DiffviewDiffDeleteDim', { link = 'Comment' })
highlight('DiffviewDiffText', { link = 'DiffText' })

-- conflict-marker.nvim
highlight('ConflictOursMarker', { bg = colors.conflict_ours })
highlight('ConflictOurs', { link = 'ConflictOursMarker' })
highlight('ConflictTheirsMarker', { bg = colors.conflict_theirs })
highlight('ConflictTheirs', { link = 'ConflictTheirsMarker' })
highlight('ConflictMid', { bg = colors.conflict_mid })
highlight('ConflictBaseMarker', { bg = colors.conflict_base })
highlight('ConflictBase', { link = 'ConflictBaseMarker' })

highlight('RainbowDelimiterRed', { fg = colors.norm })
highlight('RainbowDelimiterYellow', { fg = colors.norm_subtle })
highlight('RainbowDelimiterBlue', { fg = colors.norm_very_subtle })
highlight('RainbowDelimiterOrange', { fg = colors.bg_subtle })
highlight('RainbowDelimiterGreen', { fg = colors.bg_subtle })
highlight('RainbowDelimiterViolet', { fg = colors.bg_very_subtle })
highlight('RainbowDelimiterCyan', { fg = colors.bg_very_subtle })

highlight('BlinkIndentScope', { link = 'MiniIndentscopeSymbol' })
