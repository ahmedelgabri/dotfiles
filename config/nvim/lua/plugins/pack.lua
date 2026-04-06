local M = {}

local configured = {}
local bootstrapped = false

local function listify(value)
	if value == nil then
		return {}
	end

	if type(value) == 'string' then
		return { value }
	end

	return value
end

local function notify_error(context, err)
	vim.schedule(function()
		vim.notify(err, vim.log.levels.ERROR, {
			title = string.format('vim.pack: %s', context),
		})
	end)
end

function M.try(context, fn)
	local ok, result = xpcall(fn, debug.traceback)
	if not ok then
		notify_error(context, result)
		return false, result
	end

	return true, result
end

function M.load(names)
	for _, name in ipairs(listify(names)) do
		vim.cmd.packadd(name)
	end
end

function M.setup(key, names, fn)
	if configured[key] then
		return true
	end

	local ok = M.try('load ' .. key, function()
		M.load(names)
	end)
	if not ok then
		return false
	end

	ok = M.try('setup ' .. key, fn)
	if ok then
		configured[key] = true
	end

	return ok
end

function M.later(fn)
	vim.schedule(function()
		M.try('later', fn)
	end)
end

function M.run_command(cmd, raw_args, user_opts)
	if type(raw_args) == 'table' then
		user_opts = raw_args
		raw_args = user_opts.args
	end

	local command = ''
	if user_opts ~= nil and user_opts.mods ~= nil and user_opts.mods ~= '' then
		command = user_opts.mods .. ' '
	end

	command = command .. cmd
	if user_opts ~= nil and user_opts.bang then
		command = command .. '!'
	end
	if raw_args ~= nil and raw_args ~= '' then
		command = command .. ' ' .. raw_args
	end

	vim.api.nvim_cmd(vim.api.nvim_parse_cmd(command, {}), {})
end

function M.bootstrap()
	if bootstrapped then
		return
	end

	local function selective_load(plug_data)
		local data = plug_data.spec.data or {}
		if data.lazy then
			return
		end

		vim.cmd.packadd(plug_data.spec.name)
	end

	vim.pack.add(require 'plugins.specs', {
		load = selective_load,
		confirm = next(vim.api.nvim_list_uis()) ~= nil,
	})

	bootstrapped = true
end

return M
