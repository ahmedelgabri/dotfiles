local M = {}

M.mkview_filetype_blocklist = {
	diff = true,
	gitcommit = true,
	hgcommit = true,
}

M.quit_on_q_allowlist = {
	preview = true,
	qf = true,
	fzf = true,
	netrw = true,
	help = true,
	taskedit = true,
	diff = true,
	man = true,
	grepper = true,
}

M.colorcolumn_blocklist = {
	qf = true,
	fzf = true,
	netrw = true,
	help = true,
	markdown = true,
	startify = true,
	text = true,
	gitconfig = true,
	gitrebase = true,
	conf = true,
	tags = true,
	vimfiler = true,
	dos = true,
	json = true,
	diff = true,
	minpacprgs = true,
	gitcommit = true,
	GrepperSide = true,
}

M.heavy_plugins_blocklist = {
	taskedit = true,
	minpacprgs = true,
	starter = true,
}

--  Loosely based on: http://vim.wikia.com/wiki/Make_views_automatic
--  from https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/autoload/autocmds.vim#L20-L37
local function should_mkview(event)
	return vim.bo[event.buf].buftype == ''
		and M.mkview_filetype_blocklist[vim.bo[event.buf].filetype] == nil
		and vim.fn.exists '$SUDO_USER' == 0 -- Don't create root-owned files.
end

local function should_quit_on_q()
	return vim.wo.diff == true or M.quit_on_q_allowlist[vim.bo.filetype] == true
end

local function should_turn_off_colorcolumn()
	return vim.bo.textwidth == 0
		or vim.wo.diff == true
		or M.colorcolumn_blocklist[vim.bo.filetype] == true
		or vim.bo.buftype == 'terminal'
		or vim.bo.readonly == true
end

local function cleanup_marker(marker)
	if vim.fn.exists(marker) == 1 then
		vim.api.nvim_command('silent! call matchdelete(' .. marker .. ')')
		vim.api.nvim_command('silent! unlet ' .. marker)
	end
end

function M.mkview(event)
	if should_mkview(event) then
		local success, err = pcall(function()
			if vim.fn.haslocaldir() == 1 then
				-- We never want to save an :lcd command, so hack around it...
				vim.cmd.cd '-'
				vim.cmd.mkview()
				vim.cmd.lcd '-'
			else
				vim.cmd.mkview()
			end
		end)
		if not success then
			if
				err ~= nil
				and err:find '%f[%w]E32%f[%W]' == nil -- No file name; could be no buffer (eg. :checkhealth)
				and err:find '%f[%w]E186%f[%W]' == nil -- No previous directory: probably a `git` operation.
				and err:find '%f[%w]E190%f[%W]' == nil -- Could be name or path length exceeding NAME_MAX or PATH_MAX.
				and err:find '%f[%w]E5108%f[%W]' == nil
			then
				error(err)
			end
		end
	end
end

function M.loadview(event)
	if should_mkview(event) then
		vim.cmd.loadview { mods = { emsg_silent = true } }
		vim.cmd('silent! ' .. vim.fn.line '.' .. 'foldopen!')
	end
end

function M.quit_on_q()
	if should_quit_on_q() then
		vim.keymap.set(
			{ 'n' },
			'q',
			(
				(vim.wo.diff == true or vim.bo.filetype == 'man') and ':qa!'
				or (vim.bo.filetype == 'qf') and ':cclose'
				or (vim.bo.buftype == 'nofile') and ':q'
				or ':q'
			) .. '<cr>',
			{ buffer = true, silent = true, desc = '[Q]uit on q' }
		)
	end
end

-- Project specific override
-- Better than what I had before https://github.com/mhinz/vim-startify/issues/292#issuecomment-335006879
function M.source_project_config()
	local files = {
		'.vim/local.vim',
		'.vim/local.lua',
	}

	for _, file in pairs(files) do
		local current_file = vim.fn.findfile(file, vim.fn.expand '%:p' .. ';')

		if vim.fn.filereadable(current_file) == 1 then
			vim.api.nvim_command(string.format('silent source %s', current_file))
		end
	end
end

function M.highlight_overlength()
	if vim.bo.filetype == 'help' then
		return
	end

	cleanup_marker 'w:last_overlength'

	if should_turn_off_colorcolumn() then
		vim.api.nvim_command 'match NONE'
	else
		-- Use tw + 1 so invisble characters are not marked
		-- I have to escape the escape backslash to be able to pass it to vim
		-- Ex: I want "\(" I have to do it in Lua as "\\("
		local overlength_pattern = '\\%>' .. (vim.bo.textwidth + 1) .. 'v.\\+'
		-- [TODO]: figure out how to convert this to Lua
		vim.api.nvim_command(
			"let w:last_overlength = matchadd('OverLength', '"
				.. overlength_pattern
				.. "')"
		)
	end
end

function M.highlight_git_markers()
	cleanup_marker 'w:last_git_markers'
	-- I have to escape the escape backslash to be able to pass it to vim
	-- Ex: I want "\(" I have to do it in Lua as "\\("
	local overlength_pattern = '^\\(<\\|=\\|>\\)\\{7\\}\\([^=].\\+\\)\\?$'
	-- [TODO]: figure out how to convert this to Lua
	vim.api.nvim_command(
		"let w:last_overlength = matchadd('ErrorMsg','"
			.. overlength_pattern
			.. "')"
	)
end

function M.disable_heavy_plugins(event)
	local bufsize = vim.fn.getfsize(vim.fn.expand '%')
	local isMinified = vim.regex('\\.min\\..*$'):match_str(vim.fn.expand '%:t')

	if
		M.heavy_plugins_blocklist[vim.bo[event.buf].filetype] ~= nil
		or isMinified ~= nil
		or bufsize > 200000
	then
		if type(vim.cmd.LspStop) == 'function' then
			vim.cmd.LspStop()
		end
		if type(vim.cmd.TSBufDisable) == 'function' then
			vim.cmd.TSBufDisable 'highlight'
		end
	end
end

return M
