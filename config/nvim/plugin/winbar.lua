local utils = require '_.utils'
local au = require '_.utils.au'
local hl = require '_.utils.highlight'

local M = {}

__.winbar = M

local function get_filepath_parts()
	local base = vim.fn.expand '%:~:.:h'
	local filename = vim.fn.expand '%:~:.:t'
	local prefix = (vim.fn.empty(base) == 1 or base == '.') and '' or base .. '/'

	return { base, filename, prefix }
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

function M.get_active_winbar()
	local line = table.concat {
		'%=',
		-- '%#WhiteSpace#%*',
		filepath(),
		'%*',
		' ',
		-- '%#WhiteSpace#%*'
	}

	return line
end

function M.get_inactive_winbar()
	if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
		return ''
	end

	local line = table.concat {
		'%=',
		-- '%#WhiteSpace#%*',
		'%#LineNr#',
		'%f',
		'%*',
		' ',
		-- '%#WhiteSpace#%*'
	}

	return line
end

local function run(value)
	-- This is odd, the logic is reverse but it works. I need to figure out what's happening?
	if
		vim.bo.filetype == 'help'
		or vim.bo.filetype == 'man'
		or vim.bo.filetype == 'fzf'
		or vim.bo.filetype == 'NvimTree'
		-- floating window
		or vim.api.nvim_win_get_config(0).relative == ''
	then
		vim.opt_local.winbar = value
	else
		vim.opt_local.winbar = nil
	end
end

function M.activate()
	au.augroup('MyWinbar', {
		{
			event = { 'WinEnter', 'BufEnter' },
			pattern = { '*' },
			callback = function()
				run [[%!luaeval("__.winbar.get_active_winbar()")]]
			end,
		},
		{
			event = { 'WinLeave', 'BufLeave' },
			pattern = { '*' },
			callback = function()
				run [[%!luaeval("__.winbar.get_inactive_winbar()")]]
			end,
		},
	})
end

vim.opt.laststatus = 3

__.winbar.activate()
