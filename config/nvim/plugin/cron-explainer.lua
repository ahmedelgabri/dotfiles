local au = require '_.utils.au'

-- Heavily influnced by https://github.com/fabridamicelli/cronex.nvim and some code are copied from there
local M = {}

local mark_id = nil
M._cache = {}

-- Define patterns for the content of cron expressions of different lengths.
-- The first field is typically numeric (minute, second), subsequent fields can be more general.
local field_numeric = '[%d%-%/%*,]+'
local field_general = '[%a%d%-%/%*,%?#]+'

local cron_content_patterns_by_length = {
	[5] = field_numeric .. ('%s+' .. field_general):rep(4),
	[6] = field_numeric .. ('%s+' .. field_general):rep(5),
	[7] = field_numeric .. ('%s+' .. field_general):rep(6),
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

M.cron_from_line = function(line)
	for n = 7, 5, -1 do
		local content_pattern = cron_content_patterns_by_length[n]
		if content_pattern then
			-- Try to match with double quotes
			local full_pattern_dq = '"%s*(' .. content_pattern .. ')%s*"'
			local match = line:match(full_pattern_dq)
			if match then
				return match -- string.match with a capture returns the captured part
			end

			-- Try to match with single quotes
			local full_pattern_sq = "'%s*(" .. content_pattern .. ")%s*'"
			match = line:match(full_pattern_sq)
			if match then
				return match -- string.match with a capture returns the captured part
			end
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

vim.keymap.set({ 'n' }, '<leader>ec', function()
	if mark_id then
		vim.api.nvim_buf_del_extmark(0, ns, mark_id)
		mark_id = nil -- Clear the stored ID after deleting the mark
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

au.augroup('cron-explainer', {
	{
		event = { 'CursorMoved', 'CursorMovedI' },
		callback = function(ev)
			vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
			mark_id = nil -- Reset mark_id as the extmark is now cleared
		end,
	},
})
