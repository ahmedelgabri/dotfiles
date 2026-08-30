-- Renders `[<workspace>] <change>[*][✗][ <bookmarks>]` for jj repos.
-- The data comes from the `prompt_revs()` revset and `prompt_fields()`
-- template aliases in the jj config, shared with the shell prompt, the Claude
-- Code statusline, and the pi footer so all four render the same thing.
--
-- Statusline redraws are frequent, so they only read a cache. The cache is
-- refreshed asynchronously when a repo is first seen and whenever its
-- operation heads change, which is the cheapest signal that any jj command
-- ran. --ignore-working-copy keeps the refresh from snapshotting, which would
-- race the user's own jj commands.

local M = {}

local REFRESH_DEBOUNCE_MS = 100

---@class JjStatus
---@field text string rendered statusline segment

---@type table<string, JjStatus>
local cache = {}

---@type table<string, uv.uv_fs_event_t>
local watchers = {}

---@type table<string, uv.uv_timer_t>
local timers = {}

---@param stdout string
---@return string?
local function render(stdout)
	local fields = { bookmarks = {} }

	for line in stdout:gmatch '[^\n]+' do
		local key, value = line:match '^([^=]+)=(.*)$'
		if key == 'bookmarks' then
			-- A merge @ can have several nearest bookmarked ancestors, one line each
			if value ~= '' then
				table.insert(fields.bookmarks, value)
			end
		elseif key then
			fields[key] = value
		end
	end

	if not fields.change or fields.change == '' then
		return nil
	end

	local workspace = (fields.workspace or ''):gsub('@$', '')
	if workspace == 'default' then
		workspace = ''
	end

	local text = string.format(
		'%%#User6#%s%s%%*',
		workspace ~= '' and '[' .. workspace .. '] ' or '',
		fields.change
	)

	if fields.dirty and fields.dirty ~= '' then
		text = text .. '%#DiagnosticSignError#' .. fields.dirty .. '%*'
	end

	if fields.conflict and fields.conflict ~= '' then
		text = text .. '%#DiagnosticSignError#✗%*'
	end

	if #fields.bookmarks > 0 then
		text = text .. '%#User6# ' .. table.concat(fields.bookmarks, ',') .. '%*'
	end

	return text
end

---@param root string
local function refresh(root)
	vim.system(
		{
			'jj',
			'--ignore-working-copy',
			'--color=never',
			'log',
			'-r',
			'prompt_revs()',
			'--no-graph',
			'-T',
			'prompt_fields()',
		},
		{ cwd = root, text = true },
		vim.schedule_wrap(function(result)
			local text = result.code == 0 and render(result.stdout or '') or nil
			cache[root] = text and { text = text } or nil
			vim.cmd.redrawstatus()
		end)
	)
end

---@param root string
local function schedule_refresh(root)
	local timer = timers[root]
	if not timer then
		timer = assert(vim.uv.new_timer())
		timers[root] = timer
	end
	timer:stop()
	timer:start(REFRESH_DEBOUNCE_MS, 0, function()
		vim.schedule(function()
			refresh(root)
		end)
	end)
end

---@param root string
local function watch(root)
	if watchers[root] then
		return
	end

	-- In a secondary workspace `.jj/repo` is a file holding the path of the
	-- main repo's store, relative to `.jj`, and that is where operations land.
	local repo = vim.fs.joinpath(root, '.jj', 'repo')
	if vim.fn.isdirectory(repo) == 0 then
		local lines = vim.fn.readfile(repo)
		if lines[1] == nil or lines[1] == '' then
			return
		end
		repo =
			vim.fs.normalize(vim.fs.joinpath(vim.fs.joinpath(root, '.jj'), lines[1]))
	end
	local heads = vim.fs.joinpath(repo, 'op_heads', 'heads')
	local watcher = assert(vim.uv.new_fs_event())
	watchers[root] = watcher

	local ok = watcher:start(heads, {}, function(err)
		if err then
			watcher:stop()
			watchers[root] = nil
			return
		end
		schedule_refresh(root)
	end)

	if not ok then
		watchers[root] = nil
	end
end

---@return string?
local function buffer_root()
	local root = vim.b.jj_root
	if root ~= nil then
		return root ~= '' and root or nil
	end

	local path = vim.api.nvim_buf_get_name(0)
	root = vim.fs.root(path ~= '' and path or vim.fn.getcwd(), '.jj')
	-- Cache the miss too so non-repo buffers skip the directory walk on
	-- every redraw. Cleared by the BufEnter autocommand in the statusline.
	vim.b.jj_root = root or ''
	return root
end

--- Called from autocommands, never from the statusline itself: it may spawn.
function M.update()
	vim.b.jj_root = nil
	local root = buffer_root()
	if not root then
		return
	end

	watch(root)
	if not cache[root] then
		refresh(root)
	end
end

---@return string?
function M.info()
	local root = buffer_root()
	if not root then
		return nil
	end

	local status = cache[root]
	return status and status.text or nil
end

return M
