local M = {}

__.statuscolumn = M

-- Sign providers (like MiniDiff) place extmarks asynchronously without
-- bumping changedtick, and any change triggers a redraw, so the extmarks are
-- fetched once per redraw cycle instead of once per line. Lines are evaluated
-- top to bottom, so a non-increasing lnum marks the start of a new cycle.
local cache = { buf = -1, last_lnum = math.huge, signs = {} }

local function buf_signs(buf)
	local marks = vim.api.nvim_buf_get_extmarks(
		buf,
		-1,
		0,
		-1,
		{ type = 'sign', details = true }
	)

	local by_line = {}
	for _, mark in ipairs(marks) do
		local data = mark[4]
		if data and data.sign_hl_group then
			local lnum = mark[2] + 1
			local line = by_line[lnum]
			if not line then
				line = {}
				by_line[lnum] = line
			end
			line[#line + 1] = data
		end
	end

	return by_line
end

function M.get_signs(lnum)
	local buf = vim.api.nvim_get_current_buf()
	if buf ~= cache.buf or lnum <= cache.last_lnum then
		cache.buf = buf
		cache.signs = buf_signs(buf)
	end
	cache.last_lnum = lnum

	return cache.signs[lnum]
end

local fcs = vim.opt.fillchars:get()
function M.get_fold(lnum)
	if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then
		return '  '
	end
	return (vim.fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose)
		.. ' '
end

local function is_mini_diff_sign(data)
	return data.sign_hl_group:find 'MiniDiff' ~= nil
end

local function is_other_sign(data)
	return not data.sign_hl_group:find 'MiniDiff'
end

function M.get_filtered_signs(signs, condition)
	for _, data in ipairs(signs or {}) do
		if condition(data) then
			local str = '%#' .. data.sign_hl_group .. '#'

			if data.sign_text then
				str = str .. data.sign_text .. '%*'
			end

			return str
		end
	end

	return '  '
end

function M.num()
	if vim.wo.number then
		if vim.wo.relativenumber then
			return vim.v.relnum
		end
		return vim.v.lnum
	elseif vim.wo.relativenumber then
		return vim.v.relnum
	else
		return ''
	end
end

function M.render()
	local lnum = vim.v.lnum
	local signs = M.get_signs(lnum)

	return table.concat({
		M.num(),
		[[%=]],
		-- Fold marker
		M.get_fold(lnum),
		[[%=]],
		-- Git signs
		M.get_filtered_signs(signs, is_mini_diff_sign),
		[[%=]],
		-- Other signs
		M.get_filtered_signs(signs, is_other_sign),
	}, '')
end

-- https://www.reddit.com/r/neovim/comments/11215fn/comment/j8hs8vj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- FWIW if you use vim.o.statuscolumn = '%{%StatusColFunc()%}' emphasis on the percent signs,
-- then you can just use nvim_get_current_buf() and in the context of StatusColFunc that will be equal to get_buf(statusline_winid) trick.
-- You can see :help stl-%{ but essentially in the context of %{} the buffer is changed to that of the window for which the status(line/col)
-- is being drawn and the extra %} is so that the StatusColFunc can return things like %t and that gets evaluated to the filename

vim.o.statuscolumn = '%{%v:lua.__.statuscolumn.render()%}'
