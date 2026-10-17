-- Prints the mx definition for an old rx one, run with LuaJIT:
--
--   migrate.lua <rx definition>
--
-- rx definitions built their layouts with rex.layout, so they load with a
-- stand-in that returns mx nodes instead, and Rex does not need to run.

local dir = arg[0]:match '^(.*)/' or '.'
local lib = dofile(dir .. '/lib.lua')

local function quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function split(direction)
	return function(ratio, first, second)
		return { split = direction, ratio = ratio, first, second }
	end
end

local stand_in = {
	layout = {
		block = function(spec)
			local options = spec.options or {}
			local command = options.initial_input
			if command ~= nil then
				command = command:gsub('\n$', '')
			end
			return { cwd = options.cwd, command = command }
		end,
		horizontal = split 'horizontal',
		vertical = split 'vertical',
	},
	-- rx's own helpers used rex.exec to run `sh -c`.
	exec = function(argv)
		local words = {}
		for i, a in ipairs(argv) do
			words[i] = quote(a)
		end
		return { ok = os.execute(table.concat(words, ' ')) == 0 }
	end,
}

local path = arg[1]
local ok, err = pcall(function()
	local def = lib.load(path, nil, { rex = stand_in })
	local windows = lib.windows(def)
	io.write(
		lib.serialize(lib.migrated(path), def.root, windows, os.getenv 'HOME')
	)
end)
if not ok then
	io.stderr:write('mx: ' .. tostring(err) .. '\n')
	os.exit(1)
end
