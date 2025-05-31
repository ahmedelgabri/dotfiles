local M = {}

function M.get_icon(icon_name)
	local ICONS = {
		paste = '⍴',
		spell = '✎',
		branch = vim.env.PURE_GIT_BRANCH ~= '' and vim.fn.trim(
			vim.env.PURE_GIT_BRANCH
		) or ' ',
		error = '×',
		info = '𝒾',
		warn = '⚐',
		-- hint = '›',
		hint = ' ',
		lock = '',
		conflict = ' ',
		success = ' ',
		virtual = '●',
		search = '   ',
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
	vim.wo.linebreak = true
	vim.wo.list = false
	vim.wo.wrap = true
	vim.bo.expandtab = true

	if vim.bo.filetype == 'gitcommit' then
		-- Git commit messages body are constraied to 72 characters
		vim.bo.textwidth = 72
	else
		vim.bo.textwidth = 0
		vim.bo.wrapmargin = 0
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

-- From TJDevries
-- https://github.com/tjdevries/lazy-require.nvim
function M.lazy_require(require_path)
	return setmetatable({}, {
		__index = function(_, key)
			return require(require_path)[key]
		end,

		__newindex = function(_, key, value)
			require(require_path)[key] = value
		end,
	})
end

-- Some LSP are part of npm packages, so the binaries live inside node_modules/.bin
-- this function helps getting the correct path to the binary and falling
-- back to a global binary if none is found in the local node_modules
function M.get_lsp_bin(bin)
	-- Get the closest `node_modules` first
	local root = vim.fs.root(0, 'node_modules/.bin')
	local bin_path = string.format('%s/.bin/%s', root, bin)

	if vim.uv.fs_stat(bin_path) ~= nil then
		return bin_path
	end

	-- Then maybe we might be in a monorepo, so get the root `node_modules`, maybe it's hoisted up there
	root = vim.fs.root(0, '.git')
	bin_path = string.format('%s/node_modules/.bin/%s', root, bin)

	if vim.uv.fs_stat(bin_path) ~= nil then
		return bin_path
	end

	return bin
end

function M.append(option, list)
	return table.concat({ vim.o[option], unpack(list) }, ',')
end

function M.prepend(option, list)
	return table.concat({ unpack(list), vim.o[option] }, ',')
end

function M.remove(option, item)
	return vim
		.iter(vim.split(vim.o[option], ','))
		:filter(function(p)
			return p ~= item
		end)
		:join ','
end

return M
