local au = require '_.utils.au'
local hl = require '_.utils.highlight'
local utils = require '_.utils'

---------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------
local function get_parts(parts)
	return table.concat(
		vim.tbl_filter(function(item)
			return type(item) == 'string'
		end, parts),
		' '
	)
end

local function get_filepath_parts()
	local base = vim.fn.expand '%:~:.:h'
	local filename = vim.fn.expand '%:~:.:t'
	local prefix = (vim.fn.empty(base) == 1 or base == '.') and '' or base .. '/'

	return { base, filename, prefix }
end

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

local function firstToUpper(str)
	return (str:gsub('^%l', string.upper))
end

---------------------------------------------------------------------------------
-- Main functions
---------------------------------------------------------------------------------

local function git_info()
	if not vim.g.loaded_fugitive then
		return nil
	end

	local out = vim.fn.FugitiveHead(10)

	if out ~= '' then
		out = string.format('%s %s', utils.get_icon 'branch' .. ' ', out)
	end

	return type(out) == 'string'
			and out ~= ''
			and string.format('%%6* %s%%*', out)
		or nil
end

local function filepath()
	local parts = get_filepath_parts()
	local prefix = parts[3]
	local filename = parts[2]

	if vim.bo.modified then
		hl.group('StatusLineFilePath', { link = 'DiffChange' })
		hl.group('StatusLineNewFilePath', { link = 'DiffChange' })
	else
		hl.group('StatusLineFilePath', { link = 'User6' })
		hl.group('StatusLineNewFilePath', { link = 'User4' })
	end

	local line =
		string.format('%s%%*%%#StatusLineFilePath#%s%%*', prefix, filename)

	if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then
		line = '%#StatusLineNewFilePath#%f%*'
	end

	return string.format('%%4*%s%%*', line)
end

local function readonly()
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

-- Note that: \19 = ^S and \22 = ^V.
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

local function mode()
	local current_mode = vim.api.nvim_get_mode().mode

	if current_mode == 'n' then
		return nil
	end

	return MODES[current_mode] or 'Unknown'
end

local function rhs()
	return vim.fn.winwidth(0) > 80
			and get_parts {
				'%4*' .. line_no_indicator() .. '%*',
				'%4*%3l/%3L:%-2c%*',
			}
		or line_no_indicator()
end

local function spell()
	if vim.wo.spell then
		return string.format('%%#WarningMsg#%s%%*', utils.get_icon 'spell')
	end
	return nil
end

local function paste()
	if vim.o.paste then
		return string.format('%%#ErrorMsg#%s%%*', utils.get_icon 'paste')
	end
	return nil
end

local function file_info()
	local data = {
		vim.bo.filetype,
		vim.bo.fileformat ~= 'unix' and vim.bo.fileformat or nil,
		vim.bo.fileencoding ~= 'utf-8' and vim.bo.fileencoding or nil,
	}

	return get_parts(data)
end

local function word_count()
	if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'text' then
		return string.format('%%4*%d %s%%*', vim.fn.wordcount()['words'], 'words')
	end

	return nil
end

local function lsp_diagnostics()
	local count = {}
	local levels = {
		errors = vim.diagnostic.severity.ERROR,
		warnings = vim.diagnostic.severity.WARN,
		info = vim.diagnostic.severity.WARN,
		hints = vim.diagnostic.severity.HINT,
	}

	local label_mapping = {
		errors = 'error',
		warnings = 'warn',
		hints = 'hint',
	}

	for k, level in pairs(levels) do
		local n = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
		local label = label_mapping[k] or k

		if n ~= 0 then
			count[k] = string.format(
				'%%#DiagnosticSign' .. firstToUpper(label) .. '#%s %s%%*',
				utils.get_icon(label),
				n
			)
		end
	end

	return get_parts(count)
end

local function git_conflicts()
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

local function copilot()
	if
		vim.bo.filetype == 'ministarter' or vim.bo.filetype == 'snacks_dashboard'
	then
		return nil
	end

	local ok, supermaven = pcall(require, 'supermaven-nvim.api')

	if ok then
		return supermaven.is_running()
				and string.format(require('mini.icons').get('lsp', 'supermaven'))
			or nil
	end

	local c = utils.lazy_require 'copilot.client'

	if
		c.is_disabled() or not c.buf_is_attached(vim.api.nvim_get_current_buf())
	then
		return nil
	end

	return string.format(require('mini.icons').get('lsp', 'copilot')) .. ' '
end

---Mostly taken from https://github.com/MariaSolOs/dotfiles/blob/34c5df39e6576357a2b90e25673e44f4d33afe38/.config/nvim/lua/statusline.lua#L121-L172
---@type table<string, string?>
local progress_status = {
	client = nil,
	kind = nil,
	title = nil,
}

local function lsp_progress_component()
	local lsp_icon = require('mini.icons').get('lsp', 'event') .. ' '

	if not progress_status.client or not progress_status.title then
		local ok, clients = pcall(vim.lsp.get_clients)

		if ok and type(clients) == 'table' and #clients >= 1 then
			return lsp_icon
		end

		return nil
	end

	-- Avoid noisy messages while typing.
	if vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
		return nil
	end

	return string.format(
		'%s %s %%#DiagnosticSignInfo#%s%%*',
		'%#DiagnosticSignWarn#' .. lsp_icon .. '%*',
		progress_status.client,
		progress_status.title
	)
end

local function diff_source()
	local bufnr, source, icon
	bufnr = vim.api.nvim_get_current_buf()
	source = vim.b[bufnr].diffCompGit

	if not source then
		return nil
	end

	if source == 'git' then
		icon = require('mini.icons').get('directory', '.github')
	elseif source == 'codecompanion' then
		icon = require('mini.icons').get('lsp', 'codecompanion')
	end

	return icon
end

---------------------------------------------------------------------------------
-- Statusline
---------------------------------------------------------------------------------
local M = {}

__.statusline = M

function M.render_active()
	if vim.bo.filetype == 'fzf' then
		return get_parts {
			'%4*',
			'fzf',
			'%6*',
			'V: ctrl-v',
			'H: ctrl-s',
			'Tab: ctrl-t',
			'%*',
			'%=',
			file_info(),
		}
	end

	if vim.bo.filetype == 'oil' then
		return get_parts {
			git_info(),
			(function()
				local path = vim.fn.expand '%'
				path = path:gsub('oil://', '')

				return vim.fn.fnamemodify(path, ':.')
			end)(),
		}
	end

	local line = get_parts {
		filepath(),
		word_count(),
		readonly(),
		'%=',
		mode(),
		paste(),
		spell(),
		diff_source(),
		lsp_progress_component(),
		lsp_diagnostics(),
		git_conflicts(),
		file_info(),
		copilot(),
		rhs(),
	}

	if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
		return get_parts {
			'%#StatusLineNC#',
			filepath(),
			line,
		}
	end

	return get_parts {
		git_info(),
		line,
	}
end

function M.render_inactive()
	local line = '%#StatusLineNC#%f%* '

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
			if vim.bo.filetype == 'oil' then
				vim.o.laststatus = 0
				return
			end
			vim.o.laststatus = 2
			vim.opt_local.statusline = '%!v:lua.__.statusline.render_active()'
		end,
	},
	{
		event = { 'WinLeave', 'BufLeave' },
		pattern = '*',
		callback = function()
			if vim.bo.filetype == 'oil' then
				vim.o.laststatus = 0
				return
			end
			vim.o.laststatus = 2
			vim.opt_local.statusline = '%!v:lua.__.statusline.render_inactive()'
		end,
	},
})
