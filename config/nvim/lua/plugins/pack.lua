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

local function default_key(names)
	local normalized = listify(names)
	return normalized[#normalized]
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

-- Supports both setup(names, fn) and setup(key, names, fn).
function M.setup(key_or_names, names_or_fn, maybe_fn)
	local key = key_or_names
	local names = names_or_fn
	local fn = maybe_fn

	if fn == nil then
		names = key_or_names
		fn = names_or_fn
		key = default_key(names)
	end

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

-- Schedule non-essential plugin setup after startup settles.
function M.later(fn)
	vim.schedule(function()
		M.try('later', fn)
	end)
end

function M.lazy_cmd(names, ensure, opts)
	opts = vim.tbl_extend('force', {
		nargs = '*',
		bang = true,
	}, opts or {})

	for _, name in ipairs(listify(names)) do
		vim.api.nvim_create_user_command(name, function(user_opts)
			pcall(vim.api.nvim_del_user_command, name)
			if not ensure() then
				return
			end

			vim.cmd {
				cmd = name,
				args = user_opts.fargs,
				bang = user_opts.bang,
				mods = user_opts.smods,
			}
		end, opts)
	end
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
		-- Skip confirmation prompts during headless runs.
		confirm = next(vim.api.nvim_list_uis()) ~= nil,
	})

	bootstrapped = true
end

return M
