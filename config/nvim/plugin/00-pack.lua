if _G.Pack ~= nil then
	return
end

local Pack = {}

local function listify(value)
	if value == nil then
		return {}
	end

	if type(value) == 'table' then
		return value
	end

	return { value }
end

local function notify_error(context, err)
	vim.schedule(function()
		vim.notify(err, vim.log.levels.ERROR, {
			title = 'vim.pack: ' .. context,
		})
	end)
end

local function spec_name(spec)
	if type(spec) == 'table' and spec.name ~= nil then
		return spec.name
	end

	local src = type(spec) == 'string' and spec or spec.src
	if src == nil then
		return nil
	end

	return vim.fs.basename(src):gsub('%.git$', '')
end

function Pack.add(specs, opts)
	opts = vim.tbl_extend('force', {
		load = false,
		confirm = next(vim.api.nvim_list_uis()) ~= nil,
	}, opts or {})

	return vim.pack.add(specs, opts)
end

function Pack.load(names)
	for _, name in ipairs(listify(names)) do
		local ok, err = pcall(vim.cmd.packadd, name)
		if not ok then
			notify_error('load ' .. name, err)
			return false
		end
	end

	return true
end

function Pack.cmd(cmds, loader, opts)
	opts = vim.tbl_extend('force', {
		nargs = '*',
		bang = true,
	}, opts or {})

	for _, cmd in ipairs(listify(cmds)) do
		vim.api.nvim_create_user_command(cmd, function(user_opts)
			pcall(vim.api.nvim_del_user_command, cmd)

			if not loader() then
				return
			end

			vim.cmd {
				cmd = cmd,
				args = user_opts.fargs,
				bang = user_opts.bang,
				mods = user_opts.smods,
			}
		end, opts)
	end
end

function Pack.keys(maps, loader)
	for _, map in ipairs(maps) do
		vim.keymap.set(map.mode or 'n', map.lhs, function()
			if not loader() then
				return
			end

			return map.rhs()
		end, map.opts or {})
	end
end

function Pack.event(events, opts, callback)
	if callback == nil then
		callback = opts
		opts = {}
	end

	opts = vim.tbl_extend('force', opts or {}, {
		callback = callback,
	})

	vim.api.nvim_create_autocmd(events, opts)
end

vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		local spec = ev.data.spec
		local run = (spec.data or {}).run
		if ev.data.kind == 'delete' or type(run) ~= 'function' then
			return
		end

		local name = spec_name(spec)
		if name ~= nil then
			local ok, err = pcall(vim.cmd.packadd, name)
			if not ok then
				notify_error('load ' .. name, err)
				return
			end
		end

		local ok, err = xpcall(function()
			run(ev.data)
		end, debug.traceback)
		if not ok then
			notify_error('run hook for ' .. (name or 'unknown plugin'), err)
		end
	end,
})

_G.Pack = Pack
