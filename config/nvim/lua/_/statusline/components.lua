local utils = require '_.utils'

local M = {}

---@param parts table<number, any>
---@return string
function M.get_parts(parts)
	return table.concat(
		vim.tbl_filter(function(item)
			return type(item) == 'string'
		end, parts),
		' '
	)
end

---@return string[] Array of [base, filename, prefix]
local function get_filepath_parts()
	local full = vim.fn.expand '%:~:.'
	local base = vim.fn.fnamemodify(full, ':h')
	local filename = vim.fn.fnamemodify(full, ':t')
	local prefix = (base == '' or base == '.') and '' or base .. '/'

	return { base, filename, prefix }
end

---Display lineNoIndicator (from drzel/vim-line-no-indicator)
---@return string
local function line_no_indicator()
	local line_no_indicator_chars =
		{ '󰋙', '󰫃', '󰫄', '󰫅', '󰫆', '󰫇', '󰫈' }
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

---@param str string
---@return string
local function firstToUpper(str)
	return (str:gsub('^%l', string.upper))
end

---@param data {buf: number}
function M.format_diff_summary(data)
	local summary = vim.b[data.buf].minidiff_summary

	if summary == nil then
		return nil
	end

	local t = {}

	if summary.add and summary.add > 0 then
		table.insert(t, '%#@diff.plus#+' .. summary.add .. '%*')
	end

	if summary.change and summary.change > 0 then
		table.insert(t, '%#@diff.delta#~' .. summary.change .. '%*')
	end

	if summary.delete and summary.delete > 0 then
		table.insert(t, '%#@diff.minus#-' .. summary.delete .. '%*')
	end

	vim.b[data.buf].minidiff_summary_string = table.concat(t, ' ')
end

---@return string?
function M.git_info()
	if not vim.g.loaded_fugitive then
		return nil
	end

	local out = vim.fn.FugitiveHead(10)

	if out ~= '' then
		out = string.format('%s %s', utils.get_icon 'branch', out)
	end

	return type(out) == 'string'
			and out ~= ''
			and string.format('%%#User6#%s%%*', out)
		or nil
end

---@return string
function M.filepath()
	local parts = get_filepath_parts()
	local prefix = parts[3]
	local filename = parts[2]
	local highlight = 'User4'

	if vim.bo.modified then
		highlight = 'DiffChange'
	end

	local line = '%#' .. highlight .. '#%f%*'

	if vim.fn.empty(prefix) ~= 1 and vim.fn.empty(filename) ~= 1 then
		line = string.format('%s%%*%%#%s#%s%%*', prefix, highlight, filename)
	end

	return string.format('%%#%s#%s%%*', 'LineNr', line)
end

---@return string?
function M.readonly()
	local is_modifiable = vim.bo.modifiable == true
	local is_readonly = vim.bo.readonly == true
	local line = nil

	if not is_modifiable and is_readonly then
		line = string.format('%s RO', utils.get_icon 'lock')
	end

	if is_modifiable and is_readonly then
		line = 'RO'
	end

	if not is_modifiable and not is_readonly then
		line = utils.get_icon 'lock'
	end

	return line and string.format('%%5* %s %%w %%*', line) or nil
end

---Note that: \19 = ^S and \22 = ^V.
---@type table<string, string>
local MODES = {
	no = 'N-Operator Pending',
	nov = 'N-Operator Block',
	noV = 'N-Operator Line',
	v = 'V.',
	V = 'V·Line',
	['\22'] = 'V·Block',
	s = 'S.',
	S = 'S·Line',
	['\19'] = 'S·Block',
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
}

---@return string?
function M.mode()
	local current_mode = vim.api.nvim_get_mode().mode

	if current_mode == 'n' then
		return nil
	end

	return MODES[current_mode] or 'Unknown'
end

---@return string
function M.rhs()
	return vim.fn.winwidth(0) > 80
			and M.get_parts {
				'%#User4#%3l/%3L:%-2c%*',
				'%#User4#' .. line_no_indicator() .. '%*',
			}
		or line_no_indicator()
end

---@return string?
function M.spell()
	if vim.wo.spell then
		return string.format('%%#WarningMsg#%s%%*', utils.get_icon 'spell')
	end
	return nil
end

---@return string?
function M.paste()
	if vim.o.paste then
		return string.format('%%#ErrorMsg#%s%%*', utils.get_icon 'paste')
	end
	return nil
end

---@return string
function M.file_info()
	local data = {
		vim.bo.filetype:upper(),
		vim.bo.fileformat ~= 'unix' and vim.bo.fileformat or nil,
		vim.bo.fileencoding ~= 'utf-8' and vim.bo.fileencoding or nil,
	}

	return M.get_parts(data)
end

---@return string?
function M.word_count()
	if vim.bo.filetype == 'text' then
		return string.format(
			'%%#User4#%d %s%%*',
			vim.fn.wordcount()['words'],
			'words'
		)
	end

	return vim.g.obsidian
end

---@return string?
function M.git_conflicts()
	if
		vim.bo.filetype == 'ministarter' or vim.bo.filetype == 'snacks_dashboard'
	then
		return nil
	end

	local ok, git_conflict = pcall(require, 'git-conflict')

	if not ok then
		return nil
	end

	local count = git_conflict.conflict_count(0)

	if count == 0 then
		return nil
	end

	return string.format(
		'%%#DiagnosticSignError#%s%s%%*',
		utils.get_icon 'conflict',
		count
	)
end

---@return string?
function M.diff_source()
	local bufnr, source, icon
	bufnr = vim.api.nvim_get_current_buf()
	source = vim.b[bufnr].diffCompGit

	if not source then
		return nil
	end

	if source == 'git' then
		icon = require('mini.icons').get('directory', '.github')
	elseif source == 'codecompanion' then
		icon = require('mini.icons').get('filetype', 'codecompanion')
	end

	return icon
end

---@class LlmInfo
---@field processing boolean
---@field [number] {name: string?, model: string?}?

---@type LlmInfo
M.llm_info = {
	processing = false,
}

---@return string?
function M.get_codecompanion_status()
	local ok, mini_icons = pcall(require, 'mini.icons')
	if not ok then
		return nil
	end

	local icon = mini_icons.get('filetype', 'codecompanion') .. ' '

	if M.llm_info.processing then
		return string.format('%s Thinking...', icon)
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local info = M.llm_info[bufnr]

	if not info or not info.name then
		return nil
	end

	local hl
	icon, hl = mini_icons.get('filetype', info.name)

	local model = info.model or info.name
	local llm_name = string.format('%%#%s#%s%%*', hl, icon or info.name)
	local model_info = model and (' ' .. model) or ''
	local status = llm_name .. ' ' .. model_info

	return vim.bo.filetype == 'codecompanion'
			and string.format('%%#StatusLineLSP# %s ', status)
		or nil
end

return M
