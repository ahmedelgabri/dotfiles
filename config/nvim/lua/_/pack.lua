---@alias _.pack.Spec _.pack.PluginSpec

---@class _.pack.PluginSpec: vim.pack.Spec
---@field version? string|vim.VersionRange
---@field load? boolean
---@field event? string[]
---@field pattern? string[]
---@field ft? string[]
---@field cmd? string[]
---@field config? fun(ev?: any)
---@field build? fun(ev: vim.event.packchanged.data)

local M = {}

local builds = {}
local configs = {}
local configured = {}

---@param spec _.pack.Spec
---@return string
local function spec_name(spec)
	return spec.name or vim.fs.basename(spec.src):gsub('%.git$', '')
end

---@param spec _.pack.Spec
---@return boolean
local function should_load(spec)
	if spec.load ~= nil then
		return spec.load
	end

	return spec.event == nil and spec.ft == nil and spec.cmd == nil
end

---@param event string[]
---@param pattern? string[]
---@param callback fun(ev: any)
local function autocmd(event, pattern, callback)
	vim.api.nvim_create_autocmd(event, {
		pattern = pattern,
		once = true,
		callback = callback,
	})
end

---@param name string
---@param ev? any
local function load_one(name, ev)
	vim.cmd.packadd(name)

	local config = configs[name]
	if config == nil or configured[name] then
		return
	end

	configured[name] = true
	config(ev)
end

---@param spec _.pack.Spec
---@param name string
local function add_triggers(spec, name)
	local commands = spec.cmd or {}

	local function delete_commands()
		for _, cmd in ipairs(commands) do
			pcall(vim.api.nvim_del_user_command, cmd)
		end
	end

	local function load(ev)
		delete_commands()
		load_one(name, ev)
	end

	if spec.event ~= nil then
		autocmd(spec.event, spec.pattern, load)
	end

	if spec.ft ~= nil then
		autocmd({ 'FileType' }, spec.ft, load)
	end

	for _, cmd in ipairs(commands) do
		vim.api.nvim_create_user_command(cmd, function(ev)
			load(ev)
			vim.cmd {
				cmd = cmd,
				args = ev.fargs,
				bang = ev.bang,
				mods = ev.smods,
			}
		end, { nargs = '*', bang = true })
	end
end

---@param specs _.pack.Spec[]
function M.add(specs)
	for _, spec in ipairs(specs) do
		assert(type(spec.src) == 'string', 'pack specs must be tables with a src')

		local name = spec_name(spec)
		if spec.build ~= nil then
			builds[name] = spec.build
		end
		if spec.config ~= nil then
			configs[name] = spec.config
		end
	end

	vim.pack.add(specs, { load = false, confirm = false })

	for _, spec in ipairs(specs) do
		local name = spec_name(spec)
		add_triggers(spec, name)
		if should_load(spec) then
			load_one(name)
		end
	end
end

vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		if ev.data.kind == 'delete' then
			return
		end

		local name = ev.data.spec.name
		local build = builds[name]
		if build == nil then
			return
		end

		vim.cmd.packadd(name)
		build(ev.data)
	end,
})

return M
