-- @NOTE: Having functions availabe globally namespaced by modules is a handy thing.
-- Look into that. Because it's useful when we need to call lua from vim

_G.__ = {} -- My global namespace

-- 99.9% of the time I need to do vim.inspect, so this is a handy shortcut by adding a global P function
_G.P = function(v)
  print(vim.inspect(v))
  return v
end
