local au = require '_.utils.au'
local components = require '_.statusline.components'
local lsp = require '_.statusline.lsp'

local M = {}

__.statusline = M

-- Setup LSP progress handler
lsp.setup_progress_handler()

vim.o.laststatus = 2

---@return string
function M.render_active()
	if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
		return '%#StatusLineNC#%f%*'
	end

	if vim.bo.filetype == 'fzf' then
		return components.get_parts {
			'%#Statusline#',
			'fzf',
			'V: ctrl-v',
			'H: ctrl-s',
			'Tab: ctrl-t',
			'%*',
		}
	end

	if vim.bo.filetype == 'oil' then
		return components.get_parts {
			components.git_info(),
			vim.fn.expand '%',
		}
	end

	local line = components.get_parts {
		'%#Statusline#',
		components.git_info(),
		components.filepath(),
		components.readonly(),
		vim.b.minidiff_summary_string,
		components.git_conflicts(),
		'%=',
		components.word_count(),
		components.mode(),
		components.paste(),
		components.spell(),
		components.diff_source(),
		lsp.diagnostics(),
		lsp.progress(),
		components.get_codecompanion_status(),
		components.file_info(),
		components.rhs(),
		'%*',
	}

	return line
end

---@return string
function M.render_inactive()
	local line = '%#StatusLineNC#%f%* '

	return line
end

---------------------------------------------------------------------------------
-- Autocommands
---------------------------------------------------------------------------------
au.augroup('MyStatusLine', {
	{
		event = 'VimLeavePre',
		pattern = '*',
		callback = function()
			lsp.cleanup()
		end,
	},
	{
		event = 'User',
		pattern = {
			'CodeCompanionChatAdapter',
			'CodeCompanionChatModel',
			'CodeCompanionRequest*',
		},
		callback = function(args)
			if args.match == 'CodeCompanionRequestStarted' then
				components.llm_info.processing = true
			elseif args.match == 'CodeCompanionRequestFinished' then
				components.llm_info.processing = false
			elseif not vim.tbl_isempty(args.data) then
				local bufnr = args.data.bufnr
				components.llm_info[bufnr] = components.llm_info[bufnr] or {}
				if args.match == 'CodeCompanionChatAdapter' and args.data.adapter then
					components.llm_info[bufnr].name = args.data.adapter.name
				elseif args.match == 'CodeCompanionChatModel' and args.data.model then
					components.llm_info[bufnr].model = type(args.data.model) == 'table'
							and args.data.model[1]
						or args.data.model
				end
			end
		end,
	},
	{
		event = 'User',
		pattern = 'MiniDiffUpdated',
		callback = components.format_diff_summary,
	},

	-- https://www.reddit.com/r/neovim/comments/11215fn/comment/j8hs8vj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
	-- FWIW if you use vim.o.statuscolumn = '%{%StatusColFunc()%}' emphasis on the percent signs,
	-- then you can just use nvim_get_current_buf() and in the context of StatusColFunc that will be equal to get_buf(statusline_winid) trick.
	-- You can see :help stl-%{ but essentially in the context of %{} the buffer is changed to that of the window for which the status(line/col)
	-- is being drawn and the extra %} is so that the StatusColFunc can return things like %t and that gets evaluated to the filename
	{
		event = { 'WinEnter', 'BufEnter' },
		pattern = '*',
		callback = function()
			vim.wo.statusline = '%!v:lua.__.statusline.render_active()'
		end,
	},
	{
		event = { 'WinLeave', 'BufLeave' },
		pattern = '*',
		callback = function()
			vim.wo.statusline = '%!v:lua.__.statusline.render_inactive()'
		end,
	},
})
