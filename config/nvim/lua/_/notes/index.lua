---@class _.notes.IndexOptions
---@field quiet boolean
---@field run_qmd boolean
---@field run_embed boolean

---@class _.notes.IndexEnv
---@field HOME string
---@field NOTES_DIR string
---@field PATH string
---@field USER string
---@field XDG_CACHE_HOME string
---@field ZK_NOTEBOOK_DIR string

---@alias _.notes.IndexCommand string[]

---@class _.notes.index
local M = {}
local frontmatter = require '_.notes.frontmatter'

---@type table<string, boolean>
local skip_dirs = {
	assets = true,
}

---@return string
local function current_user()
	if vim.env.USER ~= nil and vim.env.USER ~= '' then
		return vim.env.USER
	end

	return vim.fn.system('id -un'):gsub('%s+$', '')
end

---@param user string
---@return string
local function home_dir(user)
	if vim.env.HOME ~= nil and vim.env.HOME ~= '' then
		return vim.env.HOME
	end

	return '/Users/' .. user
end

---@param home string
---@param user string
---@return nil
local function configure_path(home, user)
	vim.env.PATH = table.concat({
		home .. '/.nix-profile/bin',
		'/etc/profiles/per-user/' .. user .. '/bin',
		'/run/current-system/sw/bin',
		'/opt/homebrew/bin',
		'/usr/local/bin',
		'/usr/bin',
		'/bin',
		'/usr/sbin',
		'/sbin',
		vim.env.PATH or '',
	}, ':')
end

---@return nil
local function usage()
	print [[Usage: notes-index [--quiet] [--no-qmd] [--embed]

Refresh note indexes shared by zk, Neovim, and AI agents.]]
end

---@param args string[]
---@return _.notes.IndexOptions
local function parse_args(args)
	local opts = {
		quiet = false,
		run_qmd = true,
		run_embed = false,
	}

	for _, arg in ipairs(args) do
		if arg == '--quiet' or arg == '-q' then
			opts.quiet = true
		elseif arg == '--no-qmd' then
			opts.run_qmd = false
		elseif arg == '--embed' then
			opts.run_embed = true
		elseif arg == '--help' or arg == '-h' then
			usage()
			os.exit(0)
		else
			io.stderr:write('notes-index: unknown argument: ' .. arg .. '\n')
			os.exit(2)
		end
	end

	return opts
end

---@param opts _.notes.IndexOptions
---@param message string
---@return nil
local function log(opts, message)
	if not opts.quiet then
		io.stderr:write(message .. '\n')
	end
end

---@param path string
---@return boolean
local function is_markdown(path)
	return path:match '%.md$' ~= nil or path:match '%.markdown$' ~= nil
end

---@param dir string
---@return nil
local function normalize_empty_notes(dir)
	for name, type in vim.fs.dir(dir) do
		local path = vim.fs.joinpath(dir, name)
		if
			type == 'directory'
			and not skip_dirs[name]
			and name:sub(1, 1) ~= '.'
		then
			normalize_empty_notes(path)
		elseif type == 'file' and is_markdown(path) then
			local stat = vim.uv.fs_stat(path)
			if stat ~= nil and stat.size == 0 then
				frontmatter.normalize_path(path, { write = true })
			end
		end
	end
end

---@param cmd _.notes.IndexCommand
---@param opts _.notes.IndexOptions
---@param env _.notes.IndexEnv
---@return integer
local function run(cmd, opts, env)
	if vim.fn.executable(cmd[1]) ~= 1 then
		log(opts, 'notes-index: ' .. cmd[1] .. ' not found on PATH')
		return cmd[1] == 'qmd' and 0 or 1
	end

	local ok, process = pcall(vim.system, cmd, { env = env, text = true })
	if not ok then
		log(
			opts,
			'notes-index: failed to run ' .. cmd[1] .. ': ' .. tostring(process)
		)
		return 1
	end

	local result = process:wait()
	if not opts.quiet then
		io.stdout:write(result.stdout or '')
		io.stderr:write(result.stderr or '')
	end

	return result.code or 0
end

---@param lock_dir string
---@param opts _.notes.IndexOptions
---@param fn fun(): integer
---@return integer
local function with_lock(lock_dir, opts, fn)
	local ok = vim.uv.fs_mkdir(lock_dir, 448)
	if not ok then
		log(opts, 'notes-index: another indexing run is active')
		return 0
	end

	local status = 1
	local success, err = xpcall(function()
		status = fn()
	end, debug.traceback)

	vim.uv.fs_rmdir(lock_dir)

	if not success then
		log(opts, err)
		return 1
	end

	return status
end

---@param args? string[]
---@return nil
function M.run(args)
	local opts = parse_args(args or {})
	local user = current_user()
	local home = home_dir(user)
	configure_path(home, user)

	local notes_dir = frontmatter.notes_dir()
	if notes_dir == nil then
		log(opts, 'notes-index: notes directory does not exist')
		os.exit(1)
	end

	local cache_dir = vim.env.XDG_CACHE_HOME or (home .. '/.cache')
	vim.fn.mkdir(cache_dir, 'p')

	local env = {
		HOME = home,
		NOTES_DIR = notes_dir,
		PATH = vim.env.PATH,
		USER = user,
		XDG_CACHE_HOME = cache_dir,
		ZK_NOTEBOOK_DIR = notes_dir,
	}

	local status = with_lock(
		vim.fs.joinpath(cache_dir, 'notes-index.lock'),
		opts,
		function()
			local next_status = 0
			normalize_empty_notes(notes_dir)

			next_status = run(
				{ 'zk', 'index', '--quiet', '--notebook-dir', notes_dir },
				opts,
				env
			)
			if opts.run_qmd then
				local qmd_status = run({ 'qmd', 'update' }, opts, env)
				if qmd_status ~= 0 then
					next_status = qmd_status
				end

				if opts.run_embed then
					local embed_status = run({ 'qmd', 'embed' }, opts, env)
					if embed_status ~= 0 then
						next_status = embed_status
					end
				end
			end

			return next_status
		end
	)

	os.exit(status)
end

return M
