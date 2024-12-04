local M = {}

function M.get_icon(icon_name)
	local ICONS = {
		paste = '⍴',
		spell = '✎',
		branch = vim.env.PURE_GIT_BRANCH ~= '' and vim.fn.trim(
			vim.env.PURE_GIT_BRANCH
		) or ' ',
		error = '×',
		info = '●',
		warn = '!',
		hint = '›',
		lock = '',
		conflict = ' ',
		success = ' ',
		-- success = ' '
	}

	return ICONS[icon_name] or ''
end

function M.get_color(synID, what, mode)
	local value =
		vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(synID)), what, mode)

	if mode == 'cterm' then
		return tonumber(value)
	else
		return value
	end
end

function M.t(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.urlencode(str)
	str = string.gsub(
		str,
		"([^0-9a-zA-Z !'()*._~-])", -- locale independent
		function(c)
			return string.format('%%%02X', string.byte(c))
		end
	)

	str = string.gsub(str, ' ', '%%20')
	return str
end

function M.notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = ':: Local ::' })
end

function M.plaintext()
	vim.opt_local.spell = true
	vim.opt_local.linebreak = true
	vim.opt_local.list = false
	vim.opt_local.wrap = true
	vim.opt_local.expandtab = true

	if vim.bo.filetype == 'gitcommit' then
		-- Git commit messages body are constraied to 72 characters
		vim.opt_local.textwidth = 72
	else
		vim.opt_local.textwidth = 0
		vim.opt_local.wrapmargin = 0
	end

	-- Break undo sequences into chunks (after punctuation); see: `:h i_CTRL-G_u`
	-- https://twitter.com/vimgifs/status/913390282242232320
	vim.keymap.set({ 'i' }, '.', '.<c-g>u', { buffer = true })
	vim.keymap.set({ 'i' }, '?', '?<c-g>u', { buffer = true })
	vim.keymap.set({ 'i' }, '!', '!<c-g>u', { buffer = true })
	vim.keymap.set({ 'i' }, ',', ',<c-g>u', { buffer = true })
end

function M.firstToUpper(str)
	return (str:gsub('^%l', string.upper))
end

function M.is_rocket()
	return vim.fn.hostname() == 'rocket'
end

function M.is_x86_64()
	return vim.loop.os_uname().machine == 'x86_64'
end

function M.get_border(highlight)
	-- single border but heavier and with custom highlight when needed
	-- https://github.com/neovim/neovim/blob/99e0facf3a001608287ec6db69b01c77443c7b9d/src/nvim/api/win_config.c#L935C19-L935C57
	return {
		{ '┏', highlight or 'FloatBorder' },
		{ '━', highlight or 'FloatBorder' },
		{ '┓', highlight or 'FloatBorder' },
		{ '┃', highlight or 'FloatBorder' },
		{ '┛', highlight or 'FloatBorder' },
		{ '━', highlight or 'FloatBorder' },
		{ '┗', highlight or 'FloatBorder' },
		{ '┃', highlight or 'FloatBorder' },
	}
end

-- Event for buffer loaded
-- See https://github.com/LazyVim/LazyVim/discussions/1583
M.LazyFile = { 'BufReadPost', 'BufNewFile', 'BufWritePre' }

return M
