local M = {}

__.statuscolumn = M

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
	local signs = M.get_signs()

	return table.concat({
		M.num(),
		[[%=]],
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

-- https://www.reddit.com/r/neovim/comments/11215fn/comment/j8hs8vj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- FWIW if you use vim.opt.statuscolumn = '%{%StatusColFunc()%}' emphasis on the percent signs,
-- then you can just use nvim_get_current_buf() and in the context of StatusColFunc that will be equal to get_buf(statusline_winid) trick.
-- You can see :help stl-%{ but essentially in the context of %{} the buffer is changed to that of the window for which the status(line/col)
-- is being drawn and the extra %} is so that the StatusColFunc can return things like %t and that gets evaluated to the filename

vim.opt.statuscolumn = '%{%v:lua.__.statuscolumn.render()%}'
