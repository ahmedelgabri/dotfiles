local M = {}

local code_ns = vim.api.nvim_create_namespace 'lsp-markdown-code-blocks'
local link_ns = vim.api.nvim_create_namespace 'lsp-markdown-links'

local function is_separator(line)
	return line:match '^%s*%-%s*%-%s*%-[%-%s]*$'
		or line:match '^%s*%*%s*%*%s*%*[%*%s]*$'
		or line:match '^%s*_%s*_%s*_[ _]*$'
end

local function is_block(line)
	return line:match '^%s*#+%s'
		or line:match '^%s*>'
		or line:match '^%s*%[[^%]]+%]:'
		or line:match '^%s*[=_%-][=_%-][=_%-%s]*$'
		or line:match '^%s*</?[%a]'
		or line:match '^    '
		or line:match '^\t'
		or line:find('|', 1, true)
end

function M.reflow(markdown, opts)
	local remove_separators = opts and opts.remove_separators
	local lines = vim.split(markdown, '\n', { plain = true })
	local output = {}
	local paragraph = {}
	local paragraph_allows_soft_blank = true
	local footnotes = {}
	local footnote_by_target = {}
	local links = {}
	local fence

	local function add_footnote(label, target)
		target = vim.trim(target):gsub('^<', ''):gsub('>$', '')
		local index = footnote_by_target[target]
		if not index then
			index = #footnotes + 1
			footnote_by_target[target] = index
			table.insert(footnotes, target)
		end
		local text = string.format('%s[^%d]', label, index)
		links[text] = target
		return text
	end

	local function flush_paragraph()
		if #paragraph > 0 then
			table.insert(output, table.concat(paragraph, ' '))
			paragraph = {}
			paragraph_allows_soft_blank = true
		end
	end

	local function add_blank_line()
		if #output > 0 and output[#output] ~= '' then
			table.insert(output, '')
		end
	end

	for index, line in ipairs(lines) do
		local trimmed = vim.trim(line)
		local fence_marker = trimmed:match '^(```+)' or trimmed:match '^(~~~+)'
		if not fence and not fence_marker then
			trimmed = trimmed:gsub('!%[([^%]]*)%]%((.-)%)', add_footnote)
			trimmed = trimmed:gsub('%[([^%]]+)%]%((.-)%)', add_footnote)
		end

		if fence_marker then
			flush_paragraph()
			table.insert(output, line)
			if not fence then
				fence = fence_marker:sub(1, 1)
			elseif fence == fence_marker:sub(1, 1) then
				fence = nil
			end
		elseif fence then
			table.insert(output, line)
		elseif remove_separators and is_separator(trimmed) then
			flush_paragraph()
			add_blank_line()
		elseif trimmed == '' then
			local next_line = vim.trim(lines[index + 1] or '')
			local continues_sentence = #paragraph > 0
				and paragraph_allows_soft_blank
				and next_line:match '^[%l,%.;:%)%]]'
			if not continues_sentence then
				flush_paragraph()
				add_blank_line()
			end
		elseif
			trimmed:match '^@[%w_-]+'
			or trimmed:match '^[%-%+%*]%s+'
			or trimmed:match '^%d+[%.%)]%s+'
		then
			flush_paragraph()
			paragraph_allows_soft_blank = false
			table.insert(paragraph, trimmed)
		elseif is_block(line) then
			flush_paragraph()
			table.insert(output, line)
		else
			table.insert(paragraph, trimmed)
			if line:match '  $' or line:match '\\$' then
				flush_paragraph()
			end
		end
	end

	flush_paragraph()
	while output[#output] == '' do
		table.remove(output)
	end

	if #footnotes > 0 then
		add_blank_line()
		for index, target in ipairs(footnotes) do
			table.insert(output, string.format('[^%d]: %s', index, target))
		end
	end

	return table.concat(output, '\n'), links
end

function M.configure_window(win)
	vim.api.nvim_set_option_value('list', false, { win = win })
	vim.api.nvim_set_option_value('showbreak', 'NONE', { win = win })
	vim.api.nvim_set_option_value('breakindent', false, { win = win })

	local config = vim.api.nvim_win_get_config(win)
	config.title = ' Documentation '
	config.title_pos = 'left'
	vim.api.nvim_win_set_config(win, config)
end

local function open_link(target, source_win)
	local uri, fragment = target:match '^(file://[^#]+)#?(.*)$'
	local valid_source = source_win ~= nil
		and vim.api.nvim_win_is_valid(source_win)
	if not uri or not valid_source then
		vim.ui.open(target)
		return
	end

	local line, column = fragment:match '^(%d+),(%d+)$'
	local position = {
		line = math.max(tonumber(line) or 1, 1) - 1,
		character = math.max(tonumber(column) or 1, 1) - 1,
	}
	vim.api.nvim_set_current_win(source_win)
	vim.lsp.util.show_document({
		uri = uri,
		range = { start = position, ['end'] = position },
	}, 'utf-8', { focus = true })
end

local function conceal_code_blocks(bufnr, lines)
	vim.api.nvim_buf_clear_namespace(bufnr, code_ns, 0, -1)
	for row, line in ipairs(lines) do
		if line:match '^%s*```' or line:match '^%s*~~~' then
			vim.api.nvim_buf_set_extmark(bufnr, code_ns, row - 1, 0, {
				end_col = #line,
				conceal = '',
			})
		end
	end
end

local function decorate_links(bufnr, lines, links)
	vim.api.nvim_buf_clear_namespace(bufnr, link_ns, 0, -1)
	for text, target in pairs(links) do
		for row, line in ipairs(lines) do
			local from = 1
			while true do
				local start_col, end_col = line:find(text, from, true)
				if not start_col then
					break
				end
				vim.api.nvim_buf_set_extmark(bufnr, link_ns, row - 1, start_col - 1, {
					end_col = end_col,
					hl_group = '@markup.link.label',
					priority = 200,
					url = target,
				})
				from = end_col + 1
			end
		end
	end
end

local function link_at_cursor(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local marks = vim.api.nvim_buf_get_extmarks(
		bufnr,
		link_ns,
		{ row, 0 },
		{ row, -1 },
		{ details = true }
	)
	for _, mark in ipairs(marks) do
		local start_col, details = mark[3], mark[4]
		if col >= start_col and col < details.end_col then
			return details.url
		end
	end
end

function M.configure_hover(bufnr, win, links, source_win)
	M.configure_window(win)
	vim.api.nvim_set_option_value('conceallevel', 2, { win = win })
	vim.api.nvim_set_option_value('statusline', '', { win = win })

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	conceal_code_blocks(bufnr, lines)
	decorate_links(bufnr, lines, links)
	if source_win then
		vim.b[bufnr].lsp_hover_source_win = source_win
	end

	vim.keymap.set('n', '<C-]>', function()
		local target = link_at_cursor(bufnr)
		if target then
			open_link(target, vim.b[bufnr].lsp_hover_source_win)
			return
		end
		vim.cmd.normal { args = { vim.keycode '<C-]>' }, bang = true }
	end, { buffer = bufnr, desc = 'Open documentation link' })

	if not vim.b[bufnr].lsp_hover_statusline then
		vim.b[bufnr].lsp_hover_statusline = true
		vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
			buffer = bufnr,
			callback = function()
				vim.wo.statusline = ''
			end,
		})
	end
end

return M
