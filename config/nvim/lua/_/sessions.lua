-- Per-branch session management on top of mini.sessions: sessions are
-- named after cwd + git branch, written on focus changes and exit, and
-- only activated when nvim starts without file arguments. Called from
-- mini.nvim's config in plugin/mini.lua.
local M = {}

function M.setup()
	-- Sanitize a string to be safe for use as a filename.
	local function sanitize_for_filename(str)
		return str
			:gsub('[/%.~%^:%?%*%[\\@%s%c]+', '_')
			:gsub('_+', '_')
			:gsub('^_', '')
			:gsub('_$', '')
	end

	local function get_session_name()
		local name = sanitize_for_filename(vim.fn.getcwd())
		local obj = vim
			.system({ 'git', 'branch', '--show-current' }, { text = true })
			:wait()
		local branch = vim.trim(obj.stdout or '')
		if obj.code == 0 and branch ~= '' then
			return name .. '_' .. sanitize_for_filename(branch)
		else
			return name
		end
	end

	if vim.fn.argc(-1) == 0 then
		vim.schedule(function()
			local sessions = require 'mini.sessions'
			sessions.setup {
				file = '',
			}

			vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, {
				nested = true,
				callback = function()
					local session_name = get_session_name()

					-- Save session for current branch
					if vim.v.this_session ~= '' then
						sessions.write()
					end

					if
						sessions.detected[session_name]
						and string.find(vim.v.this_session, session_name, 1, true) == nil
					then
						return
					else
						-- If we are opening a new branch, create a session for the new branch with current state
						sessions.write(get_session_name())
					end
				end,
			})

			vim.api.nvim_create_autocmd('VimLeavePre', {
				callback = function()
					if vim.v.this_session == '' then
						return
					end

					sessions.write(get_session_name())
				end,
			})
		end)
	end
end

return M
