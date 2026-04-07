if _G.Pack ~= nil then
	return
end

--- @class Pack
local Pack = {}

--- Per-spec opts fields that get extracted from spec tables and passed to
--- vim.pack.add as the opts argument instead.
--- @type string[]
local opt_fields = { 'load', 'confirm' }

--- @alias Pack.Spec string|vim.pack.Spec|Pack.SpecWithOpts
--- @class Pack.SpecWithOpts: vim.pack.Spec
--- @field load? boolean|fun(plug_data: {spec: vim.pack.Spec, path: string})
--- @field confirm? boolean

--- @class Pack.KeyMap
--- @field mode? string|string[]
--- @field lhs string
--- @field rhs fun(): any
--- @field opts? vim.keymap.set.Opts

--- @alias Pack.Loader fun()

--- @param value? string|string[]
--- @return string[]
local function listify(value)
	if value == nil then
		return {}
	end

	if type(value) == 'table' then
		return value
	end

	return { value }
end

--- @param context string
--- @param err string
local function notify_error(context, err)
	vim.schedule(function()
		vim.notify(err, vim.log.levels.ERROR, {
			title = 'vim.pack: ' .. context,
		})
	end)
end

--- @param spec string|vim.pack.Spec
--- @return string?
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

--- @param specs Pack.Spec[]
--- @param opts? vim.pack.keyset.add
function Pack.add(specs, opts)
	local defaults = vim.tbl_extend('force', {
		confirm = next(vim.api.nvim_list_uis()) ~= nil,
	}, opts or {})

	-- Partition specs by their per-spec opts so we can batch
	-- specs with the same effective opts into a single vim.pack.add call.
	local groups = {} --- @type table<string, {specs: (string|vim.pack.Spec)[], opts: vim.pack.keyset.add}>

	for _, spec in ipairs(specs) do
		local spec_opts = vim.deepcopy(defaults)
		local clean_spec = spec

		if type(spec) == 'table' then
			local has_overrides = false
			for _, field in ipairs(opt_fields) do
				if spec[field] ~= nil then
					has_overrides = true
					break
				end
			end

			if has_overrides then
				clean_spec = {}
				for k, v in pairs(spec) do
					if k == 'load' or k == 'confirm' then
						spec_opts[k] = v
					else
						clean_spec[k] = v
					end
				end
			end
		end

		local key = tostring(spec_opts.load) .. ':' .. tostring(spec_opts.confirm)
		if not groups[key] then
			groups[key] = { specs = {}, opts = spec_opts }
		end
		table.insert(groups[key].specs, clean_spec)
	end

	for _, group in pairs(groups) do
		vim.pack.add(group.specs, group.opts)
	end
end

--- @param names string|string[]
function Pack.load(names)
	for _, name in ipairs(listify(names)) do
		local ok, err = pcall(vim.cmd.packadd, name)
		if not ok then
			notify_error('load ' .. name, err)
		end
	end
end

--- @param cmds string|string[]
--- @param loader Pack.Loader
--- @param opts? vim.api.keyset.user_command
function Pack.cmd(cmds, loader, opts)
	opts = vim.tbl_extend('force', {
		nargs = '*',
		bang = true,
	}, opts or {})

	for _, cmd in ipairs(listify(cmds)) do
		vim.api.nvim_create_user_command(cmd, function(user_opts)
			pcall(vim.api.nvim_del_user_command, cmd)
			loader()

			vim.cmd {
				cmd = cmd,
				args = user_opts.fargs,
				bang = user_opts.bang,
				mods = user_opts.smods,
			}
		end, opts)
	end
end

--- @param maps Pack.KeyMap[]
--- @param loader Pack.Loader
function Pack.keys(maps, loader)
	for _, map in ipairs(maps) do
		vim.keymap.set(map.mode or 'n', map.lhs, function()
			loader()
			return map.rhs()
		end, map.opts or {})
	end
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
