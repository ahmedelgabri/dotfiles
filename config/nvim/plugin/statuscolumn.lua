local M = {}
_G.Status = M

---@return {name:string, text:string, texthl:string}[]
function M.get_signs()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	return vim.tbl_map(function(sign)
		return vim.fn.sign_getdefined(sign.name)[1]
	end, vim.fn.sign_getplaced(buf, { group = '*', lnum = vim.v.lnum })[1].signs)
end

local fcs = vim.opt.fillchars:get()
function M.get_fold(lnum)
	if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then
		return ' '
	end
	return vim.fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose
end

function M.get_git_signs()
	-- TODO: Check in 0.10 if we can get rid of M.get_signs and use this instead
	-- https://github.com/echasnovski/mini.nvim/discussions/789#discussioncomment-9060348
	local signs = vim.api.nvim_buf_get_extmarks(
		0,
		-1,
		{ vim.v.lnum - 1, 0 },
		{ vim.v.lnum - 1, -1 },
		{ type = 'sign', details = true }
	)

	for _, sign in ipairs(signs) do
		local data = sign[4]
		if data and data.sign_hl_group and data.sign_hl_group:find 'MiniDiff' then
			return '%#' .. data.sign_hl_group .. '#' .. data.sign_text .. '%*'
		end
	end

	return '  '
end

function M.column()
	local sign

	for _, s in ipairs(M.get_signs()) do
		sign = s
	end

	local components = {
		sign and ('%#' .. sign.texthl .. '#' .. sign.text .. '%*') or '  ',
		[[%=]],
		M.get_fold(vim.v.lnum),
		[[%=]],
		M.get_git_signs(),
	}

	return table.concat(components, '')
end

vim.opt.statuscolumn = [[%!v:lua.Status.column()]]

return M
