local utils = require '_.utils'

local M = {}

---------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------
local SPINNER_UPDATE_INTERVAL = 100
local PROGRESS_CLEAR_DELAY = 1000

---@param str string
---@return string
local function firstToUpper(str)
	return (str:gsub('^%l', string.upper))
end

---@return string?
function M.diagnostics()
	local levels = {
		errors = vim.diagnostic.severity.ERROR,
		warnings = vim.diagnostic.severity.WARN,
		info = vim.diagnostic.severity.INFO,
		hints = vim.diagnostic.severity.HINT,
	}

	local label_mapping = {
		errors = 'error',
		warnings = 'warn',
		hints = 'hint',
	}

	local parts = {}

	for k, level in pairs(levels) do
		local n = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
		local label = label_mapping[k] or k

		if n ~= 0 then
			table.insert(
				parts,
				string.format(
					'%%#DiagnosticSign' .. firstToUpper(label) .. '#%s%s%%*',
					utils.get_icon(label),
					n
				)
			)
		end
	end

	if #parts > 0 then
		return '‹› ' .. table.concat(parts, ' ')
	end

	return nil
end

---------------------------------------------------------------------------------
-- LSP Progress
---------------------------------------------------------------------------------

---@class LspProgress
---@field client_id number
---@field token string|number
---@field kind string
---@field title string?
---@field percentage number?

-- Track active progress per client+token
---@type table<string, LspProgress>
local active_progress = {}

-- Spinner frames
local spinner_frames =
	{ '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local spinner_index = 1
---@type uv.uv_timer_t?
local spinner_timer = nil

local function start_spinner()
	if spinner_timer then
		return
	end

	spinner_timer = vim.loop.new_timer()
	spinner_timer:start(
		0,
		SPINNER_UPDATE_INTERVAL,
		vim.schedule_wrap(function()
			spinner_index = (spinner_index % #spinner_frames) + 1
			vim.cmd.redrawstatus()
		end)
	)
end

local function stop_spinner()
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()
		spinner_timer = nil
		spinner_index = 1
	end
end

---@param client_id number
---@param token string|number
---@return string
local function make_progress_key(client_id, token)
	return string.format('%d:%s', client_id, tostring(token))
end

---@return LspProgress[]
local function get_all_active_progress()
	-- Track one progress per client (not per token)
	---@type table<number, LspProgress>
	local by_client = {}
	for _, progress in pairs(active_progress) do
		if progress.title then
			local client_id = progress.client_id
			-- Keep the first one or prioritize "begin" over "report"
			if not by_client[client_id] or progress.kind == 'begin' then
				by_client[client_id] = progress
			end
		end
	end

	-- Convert to list
	local progress_list = {}
	for _, progress in pairs(by_client) do
		table.insert(progress_list, progress)
	end

	return progress_list
end

---@return string?
function M.progress()
	local progress_list = get_all_active_progress()

	if #progress_list == 0 then
		stop_spinner()
		local clients = vim.lsp.get_clients()

		if #clients >= 1 then
			local lsp_icon = require('mini.icons').get('lsp', 'event')
			return lsp_icon
		end

		return nil
	end

	start_spinner()

	-- Avoid noisy messages while typing.
	if vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
		return nil
	end

	-- Build progress display
	local parts = {}
	local max_items = 2

	for i, progress in ipairs(progress_list) do
		if i > max_items then
			break
		end

		local client = vim.lsp.get_client_by_id(progress.client_id)
		local client_name = client and client.name or 'LSP'
		local title = progress.title

		if progress.percentage then
			title = string.format('%s (%d%%)', title, progress.percentage)
		end

		table.insert(
			parts,
			string.format('%s %%#DiagnosticSignInfo#%s%%*', client_name, title)
		)
	end

	if #progress_list > max_items then
		table.insert(parts, string.format('+%d more', #progress_list - max_items))
	end

	return string.format(
		'%%#DiagnosticSignWarn#%s%%* %s',
		spinner_frames[spinner_index],
		table.concat(parts, ' | ')
	)
end

---Setup LSP progress handler
function M.setup_progress_handler()
	vim.lsp.handlers['$/progress'] = function(_, progress, ctx)
		if not progress or not progress.value or not progress.token then
			return
		end

		local client = vim.lsp.get_client_by_id(ctx.client_id)
		if not client then
			return
		end

		local value = progress.value
		local key = make_progress_key(ctx.client_id, progress.token)

		if value.kind == 'end' then
			-- Remove from active progress
			active_progress[key] = nil
			-- Wait a bit before clearing the status to let user see completion
			vim.defer_fn(function()
				vim.cmd.redrawstatus()
			end, PROGRESS_CLEAR_DELAY)
		else
			-- Add or update progress
			active_progress[key] = {
				client_id = ctx.client_id,
				token = progress.token,
				kind = value.kind,
				title = value.title or value.message,
				percentage = value.percentage,
			}
			vim.cmd.redrawstatus()
		end
	end
end

---Cleanup spinner on exit
function M.cleanup()
	stop_spinner()
end

return M
