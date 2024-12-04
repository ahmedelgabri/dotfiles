local M = {}

M.mkview_filetype_blocklist = {
	diff = true,
	gitcommit = true,
	hgcommit = true,
	ministarter = true,
	snacks_dashboard = true,
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
	ministarter = true,
	snacks_dashboard = true,
}

M.heavy_plugins_blocklist = {
	taskedit = true,
	minpacprgs = true,
	ministarter = true,
	snacks_dashboard = true,
}

--  Loosely based on: http://vim.wikia.com/wiki/Make_views_automatic
--  from https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/autoload/autocmds.vim#L20-L37
local function should_mkview(event)
	return vim.bo[event.buf].buftype == ''
		and M.mkview_filetype_blocklist[vim.bo[event.buf].filetype] == nil
		and vim.fn.exists '$SUDO_USER' == 0 -- Don't create root-owned files.
end

local function should_turn_off_colorcolumn()
	return vim.bo.textwidth == 0
		or vim.wo.diff == true
		or M.colorcolumn_blocklist[vim.bo.filetype] == true
		or vim.bo.buftype == 'terminal'
		or vim.bo.readonly == true
		or vim.wo.previewwindow == true
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

return M
