local au = require '_.utils.au'
local hl = require '_.utils.highlight'
local utils = require '_.utils'

---------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------

-- display lineNoIndicator (from drzel/vim-line-no-indicator)
local function line_no_indicator()
	local line_no_indicator_chars = { '⎺', '⎻', '─', '⎼', '⎽' }
	local current_line = vim.fn.line '.'
	local total_lines = vim.fn.line '$'
	local index = current_line

	if current_line == 1 then
		index = 1
	elseif current_line == total_lines then
		index = #line_no_indicator_chars
	else
		local line_no_fraction = math.floor(current_line) / math.floor(total_lines)
		index = math.ceil(line_no_fraction * #line_no_indicator_chars)
	end

	return line_no_indicator_chars[index]
end

---------------------------------------------------------------------------------
-- Main functions
---------------------------------------------------------------------------------

local function git_info()
	if not vim.g.loaded_fugitive then
		return ''
	end

	local out = vim.fn.FugitiveHead(10)

	if out ~= '' then
		out = string.format('%s %s', utils.get_icon 'branch', out)
	end

	return string.format('%%6* %s %%*', out)
end

local function update_filepath_highlights()
	if vim.bo.modified then
		hl.group('StatusLineFilePath', { link = 'DiffChange' })
		hl.group('StatusLineNewFilePath', { link = 'DiffChange' })
	else
		hl.group('StatusLineFilePath', { link = 'User6' })
		hl.group('StatusLineNewFilePath', { link = 'User4' })
	end

	return ''
end

local function get_filepath_parts()
	local base = vim.fn.expand '%:~:.:h'
	local filename = vim.fn.expand '%:~:.:t'
	local prefix = (vim.fn.empty(base) == 1 or base == '.') and '' or base .. '/'

	return { base, filename, prefix }
end

local function filepath()
	local parts = get_filepath_parts()
	local prefix = parts[3]
	local filename = parts[2]

	update_filepath_highlights()

	local line = string.format('%s%%*%%#StatusLineFilePath#%s', prefix, filename)

	if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then
		line = '%#StatusLineNewFilePath# %f %*'
	end

	return string.format('%%4*%s%%*', line)
end

local function readonly()
	local is_modifiable = vim.bo.modifiable == true
	local is_readonly = vim.bo.readonly == true
	local line = ''

	if not is_modifiable and is_readonly then
		line = string.format('%s RO', utils.get_icon 'lock')
	end

	if is_modifiable and is_readonly then
		line = 'RO'
	end

	if not is_modifiable and not is_readonly then
		line = utils.get_icon 'lock'
	end

	return string.format('%%5* %s %%w %%*', line)
end

-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed and when managed to display them they turn the file into a binary format).
-- file --mime-type statusline.lua -> application/octet-stream
local CTRL_S = vim.keycode '<C-S>'
local CTRL_V = vim.keycode '<C-V>'

local MODES = setmetatable({
	no = 'N-Operator Pending',
	nov = 'N-Operator Block',
	noV = 'N-Operator Line',
	v = 'V.',
	V = 'V·Line',
	[CTRL_V] = 'V·Block',
	s = 'S.',
	S = 'S·Line',
	[CTRL_S] = 'S·Block',
	i = 'I.',
	ic = 'I·Compl',
	ix = 'I·X-Compl',
	R = 'R.',
	Rc = 'Compl·Replace',
	Rx = 'V·Replace',
	Rv = 'X-Compl·Replace',
	c = 'Command',
	cv = 'Vim Ex',
	ce = 'Ex',
	r = 'Prompt',
	rm = 'More',
	['r?'] = 'Confirm',
	['!'] = 'Sh',
	t = 'T.',
	nt = 'TN.',
}, {
	-- By default return 'Unknown' but this shouldn't be needed
	__index = function()
		return 'Unknown'
	end,
})

local function mode()
	local current_mode = vim.api.nvim_get_mode().mode

	if current_mode == 'n' then
		return ''
	end

	return MODES[current_mode]
end

local function rhs()
	return vim.fn.winwidth(0) > 80
			and ('%%4* %s %%3l/%%3L:%%-2c %%*'):format(line_no_indicator())
		or line_no_indicator()
end

local function spell()
	if vim.wo.spell then
		return string.format('%%#WarningMsg# %s %%*', utils.get_icon 'spell')
	end
	return ''
end

local function paste()
	if vim.o.paste then
		return string.format('%%#ErrorMsg# %s %%*', utils.get_icon 'paste')
	end
	return ''
end

local function file_info()
	local line = vim.bo.filetype
	if vim.bo.fileformat ~= 'unix' then
		line = string.format('%s %s', line, vim.bo.fileformat)
	end

	if vim.bo.fileencoding ~= 'utf-8' then
		line = string.format('%s %s', line, vim.bo.fileencoding)
	end

	return string.format('%%4* %s %%*', line)
end

local function word_count()
	if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'text' then
		return string.format('%%4* %d %s %%*', vim.fn.wordcount()['words'], 'words')
	end

	return ''
end

local function orgmode()
	return _G.orgmode
			and type(_G.orgmode.statusline) == 'function'
			and _G.orgmode.statusline()
		or ''
end

local function lsp_diagnostics()
	local count = {}
	local levels = {
		errors = vim.diagnostic.severity.ERROR,
		warnings = vim.diagnostic.severity.WARN,
		info = vim.diagnostic.severity.WARN,
		hints = vim.diagnostic.severity.HINT,
	}

	for k, level in pairs(levels) do
		count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
	end

	local errors = ''
	local warnings = ''
	local hints = ''
	local info = ''

	if count.errors ~= 0 then
		errors = string.format(
			'%%#DiagnosticSignError#%s %s',
			utils.get_icon 'error',
			count.errors
		)
	end

	if count.warnings ~= 0 then
		warnings = string.format(
			'%%#DiagnosticSignWarn#%s %s',
			utils.get_icon 'warn',
			count.warnings
		)
	end

	if count.hints ~= 0 then
		hints = string.format(
			'%%#DiagnosticSignHint#%s %s',
			utils.get_icon 'hint',
			count.hints
		)
	end

	if count.info ~= 0 then
		info = string.format(
			'%%#DiagnosticSignInfo#%s %s',
			utils.get_icon 'info',
			count.info
		)
	end

	return string.format(
		'%s %s %s %s%%*',
		errors ~= '' and ' ' .. errors or errors,
		warnings,
		hints,
		info
	)
end

local function git_conflicts()
	if vim.bo.filetype == 'ministarter' then
		return ''
	end

	local ok, git_conflict = pcall(require, 'git-conflict')

	if not ok then
		return ''
	end

	local count = git_conflict.conflict_count(0)

	if count == 0 then
		return ''
	end

	return string.format(
		'%%#DiagnosticSignError#%s %s %%*',
		utils.get_icon 'conflict',
		count
	)
end

local function copilot()
	if vim.bo.filetype == 'ministarter' then
		return ''
	end

	local ok, supermaven = pcall(require, 'supermaven-nvim.api')

	local highlighted_icon = '%%#MoreMsg#%s%%* '

	if ok then
		return supermaven.is_running()
				and string.format(
					highlighted_icon,
					require('mini.icons').get('lsp', 'supermaven')
				)
			or ''
	end

	return vim.g.loaded_copilot == 1
			and string.format(
				highlighted_icon,
				require('mini.icons').get('lsp', 'copilot')
			)
		or ''
end

---Mostly taken from https://github.com/MariaSolOs/dotfiles/blob/34c5df39e6576357a2b90e25673e44f4d33afe38/.config/nvim/lua/statusline.lua#L121-L172
---@type table<string, string?>
local progress_status = {
	client = nil,
	kind = nil,
	title = nil,
}

local function lsp_progress_component()
	local lsp_icon = require('mini.icons').get('lsp', 'event')

	if not progress_status.client or not progress_status.title then
		local ok, clients = pcall(vim.lsp.get_clients)

		if ok and type(clients) == 'table' and #clients >= 1 then
			return lsp_icon .. ' '
		end

		return ''
	end

	-- Avoid noisy messages while typing.
	if vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
		return ''
	end

	return string.format(
		'%s %s %%#DiagnosticSignInfo#%s',
		'%#DiagnosticSignWarn#' .. lsp_icon .. ' %*',
		progress_status.client,
		progress_status.title
	)
end

---------------------------------------------------------------------------------
-- Statusline
---------------------------------------------------------------------------------
local M = {}

__.statusline = M

function M.render_active()
	local line = table.concat {
		filepath(),
		word_count(),
		readonly(),
		'%= ',
		mode(),
		'%*',
		paste(),
		spell(),
		orgmode(),
		lsp_progress_component(),
		lsp_diagnostics(),
		git_conflicts(),
		file_info(),
		copilot(),
		rhs(),
	}

	if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
		return table.concat {
			'%#StatusLineNC# ',
			filepath(),
			line,
		}
	end

	return table.concat {
		git_info(),
		'%<',
		line,
	}
end

function M.render_inactive()
	local line = '%#StatusLineNC#%f%*'

	return line
end

-- https://www.reddit.com/r/neovim/comments/11215fn/comment/j8hs8vj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- FWIW if you use vim.o.statuscolumn = '%{%StatusColFunc()%}' emphasis on the percent signs,
-- then you can just use nvim_get_current_buf() and in the context of StatusColFunc that will be equal to get_buf(statusline_winid) trick.
-- You can see :help stl-%{ but essentially in the context of %{} the buffer is changed to that of the window for which the status(line/col)
-- is being drawn and the extra %} is so that the StatusColFunc can return things like %t and that gets evaluated to the filename
au.augroup('MyStatusLine', {
	{
		event = 'LspProgress',
		pattern = { 'begin', 'end' },
		desc = 'Update LSP progress in statusline',
		callback = function(args)
			-- This should in theory never happen, but I've seen weird errors.
			if not args.data then
				return
			end

			progress_status = {
				client = vim.lsp.get_client_by_id(args.data.client_id).name,
				kind = args.data.params.value.kind,
				title = args.data.params.value.title,
			}

			if progress_status.kind == 'end' then
				progress_status.title = nil
				-- Wait a bit before clearing the status.
				vim.defer_fn(function()
					vim.cmd.redrawstatus()
				end, 3000)
			else
				vim.cmd.redrawstatus()
			end
		end,
	},
	{
		event = { 'WinEnter', 'BufEnter' },
		pattern = '*',
		callback = function()
			vim.opt_local.statusline = '%!v:lua.__.statusline.render_active()'
		end,
	},
	{
		event = { 'WinLeave', 'BufLeave' },
		pattern = '*',
		callback = function()
			vim.opt_local.statusline = '%!v:lua.__.statusline.render_inactive()'
		end,
	},
})
