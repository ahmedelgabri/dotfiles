local function setup()
	ps.sub('cd', function()
		local cwd = cx.active.current.cwd
		if cwd:ends_with 'Downloads' then
			ya.emit('sort', { 'mtime', reverse = true, dir_first = false })
		else
			ya.emit('sort', { 'natural', reverse = false, dir_first = true })
		end
	end)
end

return { setup = setup }
