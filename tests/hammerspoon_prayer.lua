local root = assert(arg[1], 'pass the repository root')
local realTime = os.time
local function equal(actual, expected)
	assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function timestamp(day, hour, minute)
	return realTime {
		year = 2026,
		month = 12,
		day = day,
		hour = hour,
		min = minute or 0,
		sec = 0,
	}
end
local data = {
	source = 'aladhan',
	timings = {
		fajr = '04:00',
		dhuhr = '13:00',
		asr = '17:00',
		maghrib = '21:00',
		isha = '23:00',
	},
}

local function fresh()
	local state =
		{ now = timestamp(31, 12), logs = {}, tasks = {}, notifications = {} }
	local env = setmetatable({}, { __index = _G })
	env.os = setmetatable({
		time = function(parts)
			return parts and realTime(parts) or state.now
		end,
	}, { __index = os })
	local function timer(delay, callback)
		local value = { delay = delay, callback = callback, stopped = false }
		function value:start()
			return self
		end
		function value:stop()
			self.stopped = true
		end
		return value
	end
	local logger = {}
	for _, level in ipairs { 'i', 'e', 'w', 'wf', 'ef' } do
		logger[level] = function(message, ...)
			table.insert(state.logs, string.format(message, ...))
		end
	end
	env.hs = {
		fs = {
			temporaryDirectory = function()
				return '/tmp/'
			end,
			attributes = function()
				return {}
			end,
		},
		json = {
			read = function()
				return { locality = 'Amsterdam', countryCode = 'NL' }
			end,
			decode = function(value)
				if value == 'schedule' then
					return data
				end
				if value == 'hijri' then
					return { day = 1, month = 1, year = 1448 }
				end
				error 'invalid JSON'
			end,
		},
		osascript = {
			javascript = function()
				return true, 'hijri'
			end,
		},
		image = {
			imageFromAppBundle = function()
				return nil
			end,
		},
		notify = {
			new = function(_, attributes)
				return {
					send = function()
						table.insert(state.notifications, attributes)
					end,
				}
			end,
		},
		timer = { doAfter = timer, doEvery = timer, delayed = { new = timer } },
		task = {
			new = function(shell, callback, arguments)
				local task =
					{ shell = shell, callback = callback, arguments = arguments }
				function task:start()
					return true
				end
				function task:terminate()
					self.terminated = true
				end
				table.insert(state.tasks, task)
				return task
			end,
		},
		pathwatcher = {
			new = function(path, callback)
				state.watcher = timer(path, callback)
				return state.watcher
			end,
		},
		menubar = {
			new = function()
				local menu = {}
				function menu:setTitle(value)
					self.title = value
				end
				function menu:setTooltip(value)
					self.tooltip = value
				end
				function menu:setMenu(value)
					self.menu = value
				end
				function menu:delete()
					self.deleted = true
				end
				return menu
			end,
		},
		styledtext = {
			new = function(text)
				return text
			end,
		},
	}
	local modules = { log = logger }
	env.require = function(name)
		if not modules[name] then
			modules[name] = assert(
				loadfile(root .. '/config/.hammerspoon/' .. name .. '.lua', 't', env)
			)()
		end
		return modules[name]
	end
	local prayer =
		assert(loadfile(root .. '/config/.hammerspoon/prayer.lua', 't', env))()
	prayer.settings.notificationsEnabled = false
	state.utils = env.require 'utils'
	function state:cache()
		prayer.schedule = { stamp = os.date('%d-%m-%Y', self.now), data = data }
	end
	function state:expectLogs(...)
		local expected = { ... }
		equal(#self.logs, #expected)
		for i, message in ipairs(expected) do
			equal(self.logs[i], message)
		end
		self.logs = {}
	end
	return prayer, state
end

local tests = {
	selection_and_highlighting = function()
		local prayer, state = fresh()
		state:cache()
		assert(prayer.update())
		equal(prayer.state.nextPrayer.key, 'dhuhr')
		equal(prayer.state.remainingMinutes, 60)
		equal(prayer.state.highlight, false)
		equal(prayer.state.location, 'Amsterdam, NL')
		state.now = timestamp(31, 12, 30)
		assert(prayer.update())
		equal(prayer.state.highlight, true)
		state.now = timestamp(31, 13)
		assert(prayer.update())
		equal(prayer.state.nextPrayer.key, 'asr')
		local status = prayer.getStatus()
		status.nextPrayer.key = 'changed'
		equal(prayer.state.nextPrayer.key, 'asr')
		equal(status.rowCount, 5)
		state:expectLogs()
	end,
	year_rollover_and_stale_schedule = function()
		local prayer, state = fresh()
		state.now = timestamp(31, 23, 1)
		state:cache()
		assert(prayer.update())
		equal(prayer.state.nextPrayer.key, 'fajr')
		equal(
			os.date('%Y-%m-%d %H:%M', prayer.state.nextPrayer.timestamp),
			'2027-01-01 04:00'
		)
		state.now = timestamp(32, 0)
		equal(prayer.update(), false)
		equal(#state.tasks, 1)
		assert(prayer.state.error:find 'no prayer schedule for 01%-01%-2027')
		state:expectLogs 'Fetching prayer schedule with get-prayer'
	end,
	notification_deduplication = function()
		local prayer, state = fresh()
		prayer.settings.notificationsEnabled = true
		state:cache()
		assert(prayer.update())
		local pending = prayer.notificationTimer
		equal(pending.delay, 3600)
		state.now = timestamp(31, 13)
		pending.callback()
		equal(#state.notifications, 1)
		equal(state.notifications[1].title, 'الظهر')
		equal(prayer.getStatus().sentNotificationCount, 1)
		assert(prayer.update())
		equal(#state.notifications, 1)
		equal(prayer.notificationTimer.delay, 4 * 3600)
		state:expectLogs()
	end,
	late_timer_does_not_notify = function()
		local prayer, state = fresh()
		prayer.settings.notificationsEnabled = true
		state:cache()
		prayer.update()
		state.now = timestamp(31, 13, 2)
		prayer.notificationTimer.callback()
		equal(#state.notifications, 0)
		equal(prayer.notificationTimer.delay, 3 * 3600 + 58 * 60)
		state:expectLogs()
	end,
	fetch_failure_cooldown_and_retry = function()
		local prayer, state = fresh()
		equal(prayer.update(), false)
		equal(#state.tasks, 1)
		prayer.update { forceFetch = true }
		equal(#state.tasks, 1)
		state.tasks[1].callback(1, '', 'provider failed\n')
		equal(prayer.getStatus().fetch.error, 'provider failed')
		prayer.update()
		equal(#state.tasks, 1)
		state.now = state.now + 301
		prayer.update()
		equal(#state.tasks, 2)
		state.tasks[2].callback(0, 'schedule', '')
		assert(prayer.update())
		equal(prayer.state.source, 'aladhan')
		prayer.update { forceFetch = true }
		equal(#state.tasks, 3)
		state.tasks[3].callback(0, 'malformed', '')
		equal(prayer.getStatus().fetch.error, 'invalid JSON from get-prayer')
		state:expectLogs(
			'Fetching prayer schedule with get-prayer',
			'Prayer schedule fetch failed: provider failed',
			'Fetching prayer schedule with get-prayer',
			'Prayer schedule fetch completed',
			'Fetching prayer schedule with get-prayer',
			'Prayer schedule fetch failed: invalid JSON from get-prayer'
		)
	end,
	location_watcher_and_cleanup = function()
		local prayer, state = fresh()
		assert(prayer.setup())
		state.tasks[1].callback(0, 'schedule', '')
		state.watcher.callback { '/tmp/unrelated.json' }
		equal(state.utils.debouncers['prayer.update'], nil)
		state.watcher.callback { '/tmp/.location.json' }
		assert(state.utils.debouncers['prayer.update'])
		state.utils.debouncers['prayer.update'].callback()
		equal(#state.tasks, 2)
		local menu, timer, watcher, task =
			prayer.menuBar, prayer.timer, prayer.watcher, prayer.fetchTask
		prayer.stop()
		assert(
			menu.deleted and timer.stopped and watcher.stopped and task.terminated
		)
		equal(prayer.getStatus().notificationScheduled, false)
		equal(prayer.fetchState.running, false)
		prayer.stop()
		state:expectLogs(
			'Fetching prayer schedule with get-prayer',
			'Prayer schedule fetch completed',
			'Fetching prayer schedule with get-prayer'
		)
	end,
}

local count = 0
for name, test in pairs(tests) do
	local ok, err = pcall(test)
	assert(ok, name .. ': ' .. tostring(err))
	count = count + 1
end
print(
	string.format('%d Hammerspoon prayer unit/integration checks passed.', count)
)
