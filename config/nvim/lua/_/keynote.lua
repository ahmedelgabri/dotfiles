local function keynote(range)
	vim.cmd.packadd 'nvim.tohtml'
	local html = require('tohtml').tohtml(0, {
		font = 'PragmataPro Mono Liga',
		number_lines = false,
		range = range,
	})
	local path = vim.fn.tempname() .. '.html'
	assert(vim.fn.writefile(html, path) == 0, 'Could not write HTML: ' .. path)

	-- vim.ui.open uses macOS open without tying exports to a specific browser.
	local process, err = vim.ui.open(path)
	assert(process, err)
	local result = process:wait()
	assert(result.code == 0, 'Could not open HTML: ' .. (result.stderr or ''))
	vim.notify(path)
	return path
end

return keynote
