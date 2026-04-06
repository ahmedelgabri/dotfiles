local M = {}

local configured = {}
local bootstrapped = false
local hooks_registered = false

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

local spec_cache

local function spec_src(spec)
	if type(spec) == 'string' then
		return spec
	end

	return spec.src
end

local function spec_name(spec)
	if type(spec) == 'table' and spec.name ~= nil then
		return spec.name
	end

	local src = spec_src(spec)
	if src ~= nil then
		return vim.fs.basename(src):gsub('%.git$', '')
	end
end

local function specs_by_key()
	if spec_cache ~= nil then
		return spec_cache
	end

	spec_cache = {}
	for _, spec in ipairs(require 'plugins.specs') do
		local name = spec_name(spec)
		local src = spec_src(spec)
		local resolved = {
			name = name,
			src = src,
			data = type(spec) == 'table' and spec.data or nil,
		}

		if name ~= nil then
			spec_cache[name] = resolved
		end
		if src ~= nil then
			spec_cache[src] = resolved
		end
	end

	return spec_cache
end

local function load_one(identifier, seen)
	local spec = specs_by_key()[identifier]
	local name = spec and spec.name or identifier
	local key = spec and (spec.src or spec.name) or identifier

	if seen[key] then
		return true
	end
	seen[key] = true

	for _, dep in ipairs(listify(spec and (spec.data or {}).deps)) do
		if not load_one(dep, seen) then
			return false
		end
	end

	return M.try('load ' .. name, function()
		vim.cmd.packadd(name)
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
	local seen = {}
	for _, name in ipairs(listify(names)) do
		if not load_one(name, seen) then
			return false
		end
	end

	return true
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

	local ok = M.load(names)
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

local function ensure_hooks()
	if hooks_registered then
		return
	end

	vim.api.nvim_create_autocmd('PackChanged', {
		callback = function(ev)
			local spec = ev.data.spec
			local run = (spec.data or {}).run
			if ev.data.kind == 'delete' or type(run) ~= 'function' then
				return
			end

			local plugin_name = spec.name
			local name = plugin_name or spec.src or 'unknown plugin'
			if plugin_name ~= nil and not M.load(plugin_name) then
				return
			end

			vim.api.nvim_echo({
				{
					string.format(
						'vim.pack: running hook for %s (%s)',
						name,
						ev.data.kind
					),
					'Comment',
				},
			}, true, {})
			run(ev.data)
		end,
	})

	hooks_registered = true
end

function M.bootstrap()
	if bootstrapped then
		return
	end

	ensure_hooks()

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
