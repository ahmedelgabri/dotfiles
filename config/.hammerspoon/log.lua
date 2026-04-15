--
-- Simple logging facility.
--

local defaultLogLevel = 'info'
local logger = hs.logger.new('ahmed', defaultLogLevel)

local module = {
	d = function(...)
		return logger.d(...)
	end,
	df = function(...)
		return logger.df(...)
	end,
	i = function(...)
		return logger.i(...)
	end,
	w = function(...)
		return logger.w(...)
	end,
	wf = function(...)
		return logger.wf(...)
	end,
	e = function(...)
		return logger.e(...)
	end,
	ef = function(...)
		return logger.ef(...)
	end,

	setLevel = function(level)
		logger.setLogLevel(level)
	end,
	getLevel = function()
		return logger.getLogLevel()
	end,

	debug = function()
		logger.setLogLevel 'debug'
	end,
	info = function()
		logger.setLogLevel 'info'
	end,
	verbose = function()
		logger.setLogLevel 'verbose'
	end,
	warning = function()
		logger.setLogLevel 'warning'
	end,
	error = function()
		logger.setLogLevel 'error'
	end,
	nothing = function()
		logger.setLogLevel 'nothing'
	end,
}

module['if'] = function(...)
	return logger['if'](...)
end

return module
