---@class _.notes.NormalizeOptions
---@field write? boolean

---@class _.notes.FrontmatterBlock
---@field key? string
---@field lines string[]
---@field order? integer

---@class _.notes.frontmatter
local M = {}

---@type string[]
local key_order = { 'id', 'title', 'date', 'aliases', 'tags' }
---@type table<string, integer>
local key_rank = {}
for index, key in ipairs(key_order) do
	key_rank[key] = index
end

---@param path string
---@return string
local function normalize_path(path)
	local real = vim.uv.fs_realpath(path)
	if real ~= nil then
		return vim.fs.normalize(real)
	end

	local parent = vim.fs.dirname(path)
	local parent_real = parent and vim.uv.fs_realpath(parent)
	if parent_real ~= nil then
		return vim.fs.normalize(vim.fs.joinpath(parent_real, vim.fs.basename(path)))
	end

	return vim.fs.normalize(path)
end

---@return string?
function M.notes_dir()
	local dir = vim.env.ZK_NOTEBOOK_DIR or vim.env.NOTES_DIR
	if dir == nil or dir == '' then
		return nil
	end

	local normalized = normalize_path(dir)
	if vim.uv.fs_stat(normalized) == nil then
		return nil
	end

	return normalized
end

---@param bufnr integer
---@return boolean
function M.is_note(bufnr)
	local root = M.notes_dir()
	if root == nil then
		return false
	end

	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == '' then
		return false
	end

	local normalized = normalize_path(path)
	if not vim.startswith(normalized, root .. '/') then
		return false
	end

	return normalized:match '%.md$' ~= nil
		or normalized:match '%.markdown$' ~= nil
end

---@param bufnr integer
---@return boolean
function M.is_empty(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	return #lines == 0 or (#lines == 1 and lines[1] == '')
end

---@param value? string
---@return string?
local function yaml_value(value)
	value = vim.trim(value or '')
	if value == '' then
		return nil
	end

	local quote = value:sub(1, 1)
	if quote == value:sub(-1) and (quote == '"' or quote == "'") then
		value = value:sub(2, -2)
	end

	return value:gsub("''", "'")
end

---@param value any
---@return string
local function yaml_quote(value)
	return "'" .. tostring(value):gsub("'", "''") .. "'"
end

---@param path string
---@return string
local function path_stem(path)
	local name = path ~= '' and vim.fs.basename(path) or 'Untitled'
	return (name:gsub('%.markdown$', ''):gsub('%.md$', ''))
end

---@param value? any
---@return string?
local function timestamp(value)
	if value == nil then
		return nil
	end

	value = tostring(value)
	local year, month, day, hour, min =
		value:match '^(%d%d%d%d)%-(%d%d)%-(%d%d)[T ](%d%d):(%d%d)'
	if year == nil then
		year, month, day, hour, min =
			value:match '^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)'
	end
	if year == nil then
		year, month, day = value:match '^(%d%d%d%d)%-(%d%d)%-(%d%d)'
		hour, min = '00', '00'
	end
	if year == nil then
		year, month, day = value:match '^(%d%d%d%d)(%d%d)(%d%d)'
		hour, min = '00', '00'
	end
	if year == nil then
		return nil
	end

	return string.format('%04d%02d%02d%02d%02d', year, month, day, hour, min)
end

---@param path string
---@return string
local function title_from_path(path)
	local title = path_stem(path)
	return title:match '^%d%d%d%d%d%d%d%d%d%d%d%d[%s_-]+(.+)$'
		or title:match '^%d%d%d%d%-%d%d%-%d%d[%s_-]+(.+)$'
		or title
end

---@param lines string[]
---@return integer?
local function frontmatter_end(lines)
	if lines[1] ~= '---' then
		return nil
	end

	for index = 2, #lines do
		if lines[index] == '---' or lines[index] == '...' then
			return index
		end
	end

	return nil
end

---@param lines string[]
---@param stop integer
---@return _.notes.FrontmatterBlock[]
---@return table<string, _.notes.FrontmatterBlock>
local function parse_blocks(lines, stop)
	---@type _.notes.FrontmatterBlock[]
	local blocks = {}
	---@type table<string, _.notes.FrontmatterBlock>
	local by_key = {}
	local index = 2

	while index < stop do
		local key = lines[index]:match '^([%w_-]+):'
		local start = index
		index = index + 1

		while index < stop and not lines[index]:match '^[%w_-]+:' do
			index = index + 1
		end

		local block = {
			key = key,
			lines = vim.list_slice(lines, start, index - 1),
			order = #blocks + 1,
		}
		table.insert(blocks, block)
		if key ~= nil then
			by_key[key] = block
		end
	end

	return blocks, by_key
end

---@param block? _.notes.FrontmatterBlock
---@return string?
local function block_value(block)
	if block == nil or block.lines[1] == nil then
		return nil
	end

	return yaml_value(block.lines[1]:match '^[%w_-]+:%s*(.-)%s*$')
end

---@param block? _.notes.FrontmatterBlock
---@return string[]
local function parse_aliases(block)
	if block == nil then
		return {}
	end

	local aliases = {}
	local inline = block.lines[1]:match '^[%w_-]+:%s*%[(.*)%]%s*$'
	if inline ~= nil then
		for value in inline:gmatch '[^,]+' do
			local alias = yaml_value(value)
			if alias ~= nil then
				table.insert(aliases, alias)
			end
		end
		return aliases
	end

	for _, line in ipairs(block.lines) do
		local alias = yaml_value(line:match '^%s*%-%s*(.-)%s*$')
		if alias ~= nil then
			table.insert(aliases, alias)
		end
	end

	return aliases
end

---@param aliases string[]
---@param alias string
---@return boolean
local function has_alias(aliases, alias)
	for _, existing in ipairs(aliases) do
		if existing == alias then
			return true
		end
	end

	return false
end

---@param key string
---@param lines string[]
---@return _.notes.FrontmatterBlock
local function block(key, lines)
	return { key = key, lines = lines }
end

---@param key string
---@param value any
---@return _.notes.FrontmatterBlock
local function scalar_block(key, value)
	return block(key, { key .. ': ' .. yaml_quote(value) })
end

---@param aliases string[]
---@return _.notes.FrontmatterBlock
local function aliases_block(aliases)
	return block('aliases', {
		'aliases: [' .. table.concat(vim.tbl_map(yaml_quote, aliases), ', ') .. ']',
	})
end

---@param lines string[]
---@param body_start integer
---@return string?
local function heading_title(lines, body_start)
	for index = body_start, #lines do
		local title = lines[index]:match '^#%s+(.+)%s*$'
		if title ~= nil then
			return vim.trim(title:gsub('%s+#*%s*$', ''))
		end
	end

	return nil
end

---@param blocks _.notes.FrontmatterBlock[]
---@return _.notes.FrontmatterBlock[]
local function ordered(blocks)
	table.sort(blocks, function(left, right)
		local left_rank = key_rank[left.key]
		local right_rank = key_rank[right.key]
		if left_rank ~= nil or right_rank ~= nil then
			return (left_rank or math.huge) < (right_rank or math.huge)
		end

		return left.order < right.order
	end)

	return blocks
end

---@param blocks _.notes.FrontmatterBlock[]
---@return string[]
local function render(blocks)
	local lines = { '---' }
	for _, item in ipairs(ordered(blocks)) do
		vim.list_extend(lines, item.lines)
	end
	table.insert(lines, '---')
	return lines
end

---@param bufnr integer
---@return nil
local function write_buffer(bufnr)
	vim.api.nvim_buf_call(bufnr, function()
		vim.cmd 'silent write'
	end)
end

---@param bufnr? integer
---@param opts? _.notes.NormalizeOptions
---@return boolean changed
function M.normalize(bufnr, opts)
	bufnr = bufnr or 0
	opts = opts or {}

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local stop = frontmatter_end(lines)
	local body_start = stop and stop + 1 or 1
	---@type _.notes.FrontmatterBlock[]
	local blocks = {}
	---@type table<string, _.notes.FrontmatterBlock>
	local by_key = {}

	if stop ~= nil then
		blocks, by_key = parse_blocks(lines, stop)
	end

	local id = timestamp(block_value(by_key.id))
		or timestamp(path_stem(path))
		or timestamp(block_value(by_key.date))
		or os.date '%Y%m%d%H%M'
	local title = block_value(by_key.title)
		or heading_title(lines, body_start)
		or title_from_path(path)
	local aliases = parse_aliases(by_key.aliases)
	local alias = title ~= '' and title or id

	if not has_alias(aliases, alias) then
		table.insert(aliases, alias)
	end

	by_key.id = scalar_block('id', id)
	by_key.title = scalar_block('title', title)
	by_key.aliases = aliases_block(aliases)

	local emitted = {}
	local next_blocks = {}
	for _, item in ipairs(blocks) do
		if item.key ~= nil and by_key[item.key] ~= nil then
			table.insert(
				next_blocks,
				vim.tbl_extend('force', by_key[item.key], { order = item.order })
			)
			emitted[item.key] = true
		else
			table.insert(next_blocks, item)
		end
	end

	for _, key in ipairs(key_order) do
		if by_key[key] ~= nil and not emitted[key] then
			table.insert(
				next_blocks,
				vim.tbl_extend('force', by_key[key], {
					order = #blocks + #next_blocks + 1,
				})
			)
			emitted[key] = true
		end
	end

	local next_lines = render(next_blocks)
	if stop == nil then
		local body = lines
		if #body == 1 and body[1] == '' then
			body = {}
		end
		table.insert(next_lines, '')
		vim.list_extend(next_lines, body)
	else
		vim.list_extend(next_lines, vim.list_slice(lines, stop + 1))
	end

	if vim.deep_equal(lines, next_lines) then
		return false
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, next_lines)
	if opts.write then
		write_buffer(bufnr)
	end

	return true
end

---@param path string
---@param opts? _.notes.NormalizeOptions
---@return boolean changed
function M.normalize_path(path, opts)
	local bufnr = vim.fn.bufnr(path)
	local existing = bufnr ~= -1
	if not existing then
		bufnr = vim.fn.bufadd(path)
	end

	vim.fn.bufload(bufnr)
	local changed = M.normalize(bufnr, opts)

	if not existing then
		pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
	end

	return changed
end

return M
