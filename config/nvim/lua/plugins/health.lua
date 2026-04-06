local M = {}

local function listify(value)
	if value == nil then
		return {}
	end

	if type(value) == 'string' then
		return { value }
	end

	return value
end

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

local function build_registry()
	local registry = {
		by_name = {},
		by_src = {},
		duplicates = {},
		stats = {
			total = 0,
			lazy = 0,
			build_hooks = 0,
		},
	}

	for _, spec in ipairs(require 'plugins.specs') do
		local src = spec_src(spec)
		local name = spec_name(spec)
		local data = type(spec) == 'table' and spec.data or {}
		local entry = {
			name = name,
			src = src,
			data = data,
		}

		registry.stats.total = registry.stats.total + 1
		if data.lazy then
			registry.stats.lazy = registry.stats.lazy + 1
		end
		if type(data.run) == 'function' then
			registry.stats.build_hooks = registry.stats.build_hooks + 1
		end

		if name ~= nil and registry.by_name[name] ~= nil then
			table.insert(registry.duplicates, 'duplicate plugin name: ' .. name)
		end
		if src ~= nil and registry.by_src[src] ~= nil then
			table.insert(registry.duplicates, 'duplicate plugin source: ' .. src)
		end

		if name ~= nil then
			registry.by_name[name] = entry
		end
		if src ~= nil then
			registry.by_src[src] = entry
		end
	end

	return registry
end

local function check_dependencies(registry)
	local issues = {}

	for _, entry in pairs(registry.by_name) do
		for _, dep in ipairs(listify((entry.data or {}).deps)) do
			if registry.by_src[dep] == nil then
				table.insert(
					issues,
					string.format('%s depends on unknown source %s', entry.name, dep)
				)
			end
		end
	end

	return issues
end

local function scan_plugin_references(registry)
	local issues = {}
	local plugin_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'plugins')

	for _, file in ipairs(vim.fn.globpath(plugin_dir, '*.lua', false, true)) do
		local basename = vim.fs.basename(file)
		if basename ~= 'health.lua' then
			local text = table.concat(vim.fn.readfile(file), '\n')

			for name in text:gmatch("pack%.load%s*'([^']+)'") do
				if registry.by_name[name] == nil then
					table.insert(
						issues,
						string.format('%s references unknown pack.load target %s', basename, name)
					)
				end
			end

			for block in text:gmatch 'pack%.load%s*%b{}' do
				for name in block:gmatch("'([^']+)'") do
					if registry.by_name[name] == nil then
						table.insert(
							issues,
							string.format(
								'%s references unknown pack.load target %s',
								basename,
								name
							)
						)
					end
				end
			end

			for name in text:gmatch("pack%.setup%s*%(%s*'([^']+)'") do
				if registry.by_name[name] == nil then
					table.insert(
						issues,
						string.format('%s references unknown pack.setup target %s', basename, name)
					)
				end
			end
		end
	end

	return issues
end

function M.check()
	vim.health.start 'plugins.pack'

	local registry = build_registry()
	vim.health.info(
		string.format(
			'%d specs registered (%d lazy, %d build hooks)',
			registry.stats.total,
			registry.stats.lazy,
			registry.stats.build_hooks
		)
	)

	if vim.tbl_isempty(registry.duplicates) then
		vim.health.ok 'spec registry has no duplicate names or sources'
	else
		for _, issue in ipairs(registry.duplicates) do
			vim.health.error(issue)
		end
	end

	local dep_issues = check_dependencies(registry)
	if vim.tbl_isempty(dep_issues) then
		vim.health.ok 'spec dependency URLs resolve to registered plugins'
	else
		for _, issue in ipairs(dep_issues) do
			vim.health.error(issue)
		end
	end

	local ref_issues = scan_plugin_references(registry)
	if vim.tbl_isempty(ref_issues) then
		vim.health.ok 'pack.load and pack.setup references point at registered plugins'
	else
		for _, issue in ipairs(ref_issues) do
			vim.health.error(issue)
		end
	end
end

return M
