---@diagnostic disable: undefined-global

-- https://pandoc.org/lua-filters.html
-- Filter to remove inline links from markdown
-- Also adds some metadata to the generated frontmatter

local base = ''

local function fix_link(url)
	return url:sub(1, 1) == '/' and base .. url or url
end

local function parse_url(url)
	-- selene: allow(undefined_variable)
	local url_pattern = re.compile [[
    url <- {|
        {:scheme: [a-zA-Z][a-zA-Z0-9+-.]* :} "://"
        {:host: [^/:?#]+ :}
        (":" {:port: [0-9]+ :})?
        {:path: "/" [^?#]* :}?
        ("?" {:query: [^#]* :})?
        ("#" {:fragment: .* :})?
    |}
]]

	local parsed_url = url_pattern:match(url)

	return parsed_url
end

-- selene: allow(undefined_variable)
-- selene: allow(unused_variable)
function Meta(m)
	local parsed_url = parse_url(m.source)

	if parsed_url ~= nil then
		base = parsed_url.scheme .. '://' .. parsed_url.host
	end

	if m.date == nil then
		m.date = os.date '%Y-%m-%d'
	end

	m.id = os.date '%Y%m%d%H%M%S'
	m.published = ''
	m.tags = { 'saved-articles' }
	m.category = '"[[saved-articles]]"'
	m.author = { m.author or '' }

	return m
end

-- selene: allow(unused_variable)
function Link(link)
	if link.target:match '^#' then
		return link.content
	end

	link.target = fix_link(link.target)

	return link
end

-- selene: allow(unused_variable)
function Image(img)
	img.src = fix_link(img.src)
	return img
end

return { { Meta = Meta }, { Link = Link, Image = Image } }
