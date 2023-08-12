local utils = require '_.utils'
local au = require '_.utils.au'
local hl = require '_.utils.highlight'
local cmds = require '_.autocmds'

au.augroup('__MyCustomColors__', {
	{
		event = 'ColorScheme',
		pattern = '*',
		callback = function()
			---------------------------------------------------------------
			-- COMPLETION
			---------------------------------------------------------------
			-- matched item (what you typed until present)
			hl.group('CmpItemAbbrMatch', {
				fg = utils.get_color('DiffAdd', 'fg', 'gui'),
				bold = true,
				italic = true,
			})

			-- fuzzy match for what you typed
			-- hl.group_cb('CmpItemAbbrMatchFuzzy', {link='DiffDelete'})

			local config = {
				link = 'NonText',
			}

			-- type of completion snippet, function, etc... can also be highlighted
			-- separately if needed
			hl.group('CmpItemKind', config)

			-- the source of the completion
			hl.group('CmpItemMenu', config)

			-- uncompleted item that may be good for completion
			hl.group('CmpItemAbbr', { link = 'NonText' })

			---------------------------------------------------------------
			-- GENERAL
			---------------------------------------------------------------
			vim.cmd [[hi! clear SignColumn]]
			vim.cmd [[hi! Tabline cterm=NONE gui=NONE]]
			vim.cmd [[hi! TablineFill cterm=NONE gui=NONE]]
			hl.group('TablineSel', { reverse = true })
			vim.cmd [[hi! NonText cterm=NONE gui=NONE]]
			vim.cmd [[hi! NormalFloat cterm=NONE gui=NONE]]
			hl.group('FloatBorder', { link = 'Number' })

			if vim.opt.background:get() == 'dark' then
				hl.group('VertSplit', {
					bg = nil,
					fg = '#333333',
					ctermbg = nil,
					ctermfg = 14,
				})
			end

			hl.group('OverLength', {
				fg = nil,
				bg = '#222222',
				ctermbg = 234,
				ctermfg = nil,
			})
			hl.group('LspDiagnosticsDefaultError', { link = 'DiffDelete' })
			hl.group('LspDiagnosticsDefaultWarning', { link = 'DiffChange' })
			hl.group('LspDiagnosticsDefaultHint', { link = 'NonText' })
			hl.group('User5', {
				fg = 'red',
				ctermfg = 'red',
			})
			hl.group('User7', {
				fg = 'cyan',
				ctermfg = 'cyan',
			})
			hl.group('User4', {
				bg = nil,
				fg = utils.get_color('NonText', 'fg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('NonText', 'fg', 'cterm'),
			})
			hl.group('StatusLine', {
				bg = nil,
				fg = utils.get_color('Identifier', 'fg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('Identifier', 'fg', 'cterm'),
			})
			hl.group('StatusLineNC', {
				italic = true,
				bg = nil,
				fg = utils.get_color('NonText', 'fg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('NonText', 'fg', 'cterm'),
			})
			hl.group('PmenuSel', {
				blend = 0,
			})
			hl.group('MutedImports', {
				bg = nil,
				fg = utils.get_color('Ignore', 'fg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('Ignore', 'fg', 'cterm'),
			})
			hl.group('MutedImportsInfo', {
				italic = true,
				bold = true,
				bg = nil,
				fg = utils.get_color('Comment', 'fg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('Comment', 'fg', 'cterm'),
			})
			hl.group('NvimTreeGitDirty', { link = 'DiffChange' })
			hl.group('NvimTreeGitStaged', { link = 'DiffChange' })
			hl.group('NvimTreeGitMerge', { link = 'DiffText' })
			hl.group('NvimTreeGitRenamed', { link = 'DiffChange' })
			hl.group('NvimTreeGitNew', { link = 'DiffAdd' })
			hl.group('NvimTreeGitDeleted', { link = 'DiffDelete' })

			hl.group('MiniIndentscopeSymbol', { link = 'Comment' })
			hl.group('MiniIndentscopeSymbolOff', { link = 'MiniIndentscopeSymbol' })
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
			hl.group('StartifyFile', { link = 'Directory' })
			hl.group('StartifyPath', { link = 'LineNr' })
			hl.group('StartifySlash', { link = 'StartifyPath' })
			hl.group('StartifyBracket', { link = 'StartifyPath' })
			hl.group('StartifyNumber', { link = 'Title' })
		end,
	},
	---------------------------------------------------------------
	-- PLAIN
	---------------------------------------------------------------
	{
		event = 'ColorScheme',
		pattern = { 'plain', 'plain-lua' },
		callback = function()
			hl.group('LineNr', {
				bg = nil,
				fg = utils.get_color('VisualNOS', 'bg', 'gui'),
				ctermbg = nil,
				ctermfg = utils.get_color('VisualNOS', 'bg', 'cterm'),
			})
			hl.group('Comment', {
				italic = true,
				bg = nil,
				fg = '#555555',
				ctermbg = nil,
				ctermfg = 236,
			})
			hl.group('Pmenu', {
				bg = '#222222',
				fg = utils.get_color('Pmenu', 'fg', 'gui'),
				ctermbg = 234,
				ctermfg = utils.get_color('Pmenu', 'fg', 'cterm'),
			})
			hl.group('PmenuSel', { link = 'ColorColumn' })
			hl.group('Whitespace', {
				fg = '#333333',
				ctermfg = 235,
			})
			hl.group('graphqlString', { link = 'Comment' })
			hl.group('Todo', { link = 'Comment' })
			hl.group('Conceal', { link = 'NonText' })
			hl.group('Error', { link = 'ErrorMsg' })
			hl.group('SnapSelect', { link = 'CursorLine' })
			hl.group('SnapMultiSelect', { link = 'DiffAdd' })
			hl.group('SnapNormal', { link = 'Normal' })
			hl.group('SnapBorder', { link = 'SnapNormal' })
			hl.group('SnapPrompt', { link = 'NonText' })
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
vim.cmd [[silent! colorscheme plain-lua]]
