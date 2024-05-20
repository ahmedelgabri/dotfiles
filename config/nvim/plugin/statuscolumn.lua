local M = {}
_G.Status = M

function M.get_signs()
	return vim.api.nvim_buf_get_extmarks(
		0,
		-1,
		{ vim.v.lnum - 1, 0 },
		{ vim.v.lnum - 1, -1 },
		{ type = 'sign', details = true }
	)
end

local fcs = vim.opt.fillchars:get()
function M.get_fold(lnum)
	if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then
		return '  '
	end
	return (vim.fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose)
		.. ' '
end

function M.get_filtered_signs(signs, condition)
	local cond = function(data)
		if condition ~= nil then
			return condition(data)
		end
		return true
	end

	for _, sign in ipairs(signs) do
		local data = sign[4]
		if data and data.sign_hl_group and cond(data) then
			return '%#' .. data.sign_hl_group .. '#' .. data.sign_text .. '%*'
		end
	end

	return '  '
end

function M.column()
	local signs = M.get_signs()

	return table.concat({
		-- Fold marker
		M.get_fold(vim.v.lnum),
		[[%=]],
		-- Git signs
		M.get_filtered_signs(signs, function(data)
			return data.sign_hl_group:find 'MiniDiff'
		end),
		[[%=]],
		-- Other signs
		M.get_filtered_signs(signs, function(data)
			return not data.sign_hl_group:find 'MiniDiff'
		end),
	}, '')
end

vim.opt.statuscolumn = [[%!v:lua.Status.column()]]

return M
