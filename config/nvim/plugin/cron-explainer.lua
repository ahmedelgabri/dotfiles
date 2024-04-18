local au = require '_.utils.au'

-- Heavily influnced by https://github.com/fabridamicelli/cronex.nvim and some code are copied from there
local M = {}

M._cache = {}

--Define s to match cronexp in a line. One of three possible lengths (7,6,5)
local first = '[\'"]%s?[%d%-%/%*,]+%s' -- Should we allow letters here too?
local part = '[%a%d%-%/%*,%?#]+%s'
local last = '[%a%d%-%/%*,%?#]+%s?[\'"]'
local nparts2pat = {
	[7] = first .. part .. part .. part .. part .. part .. last,
	[6] = first .. part .. part .. part .. part .. last,
	[5] = first .. part .. part .. part .. last,
}

-- "0 15 * * 1-5"

M.get_cmd = function()
	if vim.fn.executable 'hcron' == 1 then
		return 'hcron'
	end
end

M.explain = function(cron_expression)
	local cmd = M.get_cmd()
	if not cmd then
		vim.notify('cron explainer command not found', vim.log.levels.ERROR)
	end

	local cached = M._cache[cron_expression]

	if cached then
		return cached
	end

	local full_cmd = { cmd, '-24-hour', cron_expression }

	local output = ''

	local job_id = vim.fn.jobstart(full_cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data, _)
			output = output .. table.concat(data)
			M._cache[cron_expression] = output
		end,
		on_stderr = function(_, data, _)
			vim.notify(string.format('Error: %s', vim.inspect(data)))
		end,
		pty = true, -- IMPORTANT, otherwise it hangs up!
	})

	vim.fn.jobwait({ job_id }, 2000)

	return vim.fn.split(output, ': ')[2]
end

M.get_cron_for_pat = function(line, pat)
	-- Only allow 1 expression per line
	local n_quotes = 0
	for _ in string.gmatch(line, '[\'"]') do
		n_quotes = n_quotes + 1
	end
	if n_quotes > 2 then
		return nil
	end

	-- Build match and count as we go
	local match = ''
	local n_matches = 0
	for m in string.gmatch(line, pat) do
		n_matches = n_matches + 1
		match = match .. m
	end
	if match == '' or n_matches > 1 then
		return nil
	end

	-- Remove " and '
	local clean = ''
	for i = 1, #match do
		local c = string.sub(match, i, i)
		if c ~= "'" and c ~= '"' then
			clean = clean .. c
		end
	end

	-- Strip white space at beginning and end
	if string.sub(clean, 1, 1) == ' ' then
		clean = string.sub(clean, 2)
	end
	if string.sub(clean, -1, -1) == ' ' then
		clean = string.sub(clean, 0, -2)
	end

	return clean
end

M.cron_from_line = function(line)
	for n = 7, 5, -1 do
		local pat = nparts2pat[n]
		local match = M.get_cron_for_pat(line, pat)
		if match then
			return match
		end
	end
	return nil
end

local ns = vim.api.nvim_create_namespace 'cron-explainer'

M.render = function(info)
	local cursor = vim.api.nvim_win_get_cursor(0)

	return vim.api.nvim_buf_set_extmark(
		0,
		ns,
		cursor[1] - 1,
		0,
		{ virt_text = { { '󰥔  ' .. info, 'DiagnosticVirtualTextInfo' } } }
	)
end

local mark_id = nil

vim.keymap.set({ 'n' }, '<leader>ec', function()
	if mark_id then
		vim.api.nvim_buf_del_extmark(0, ns, mark_id)
	end

	local expression = M.cron_from_line(vim.fn.getline '.')

	if expression then
		local data = M._cache[expression]

		if not data then
			data = vim.trim(M.explain(expression))
			M._cache[expression] = data
		end

		mark_id = M.render(data)
	end
end, { desc = 'Explain a cron expression' })

-- @TODO: Why is it not working?
-- au.augroup('cron-explainer', {
-- 	{
-- 		event = { 'CursorMoved', 'CursorMovedI' },
-- 		callback = function()
-- 			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
-- 		end,
-- 		buffer = 0,
-- 	},
-- })
