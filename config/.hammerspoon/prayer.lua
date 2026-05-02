local log = require 'log'
local utils = require 'utils'

local PRAYERS = {
	{ key = 'fajr', label = 'Fajr', arabicLabel = 'الفجر' },
	{ key = 'dhuhr', label = 'Dhuhr', arabicLabel = 'الظهر' },
	{ key = 'asr', label = 'Asr', arabicLabel = 'العصر' },
	{ key = 'maghrib', label = 'Maghrib', arabicLabel = 'المغرب' },
	{ key = 'isha', label = 'Isha', arabicLabel = 'العشاء' },
}

local RED = { red = 1, green = 0, blue = 0, alpha = 1 }
local DIM = { white = 0.5, alpha = 1 }
local DIM_RED = { red = 0.95, green = 0.35, blue = 0.35, alpha = 1 }
local RLE = '\u{202B}'
local PDF = '\u{202C}'
local HIJRI_MONTHS = {
	[1] = 'محرم',
	[2] = 'صفر',
	[3] = 'ربيع الأول',
	[4] = 'ربيع الآخر',
	[5] = 'جمادى الأولى',
	[6] = 'جمادى الآخرة',
	[7] = 'رجب',
	[8] = 'شعبان',
	[9] = 'رمضان',
	[10] = 'شوال',
	[11] = 'ذو القعدة',
	[12] = 'ذو الحجة',
}
local MENU_TEXT_STYLE = {
	font = { size = 14 },
	paragraphStyle = {
		alignment = 'left',
		baseWritingDirection = 'leftToRight',
		tabStops = {
			{ location = 90, tabStopType = 'left' },
			{ location = 330, tabStopType = 'right' },
		},
	},
}

local DEFAULT_SETTINGS = {
	autosaveName = 'prayer-times',
	cacheDir = hs.fs.temporaryDirectory(),
	cacheFetchCommand = '~/.config/tmux/scripts/get-prayer',
	cacheFetchCooldownSeconds = 300,
	cacheFetchShell = '/bin/zsh',
	locationPath = hs.fs.temporaryDirectory() .. '.location.json',
	notificationGraceSeconds = 90,
	notificationsEnabled = true,
	refreshIntervalSeconds = 60,
	warningThresholdMinutes = 30,
}

local M = {
	cacheFetchState = {
		running = false,
	},
	cacheFetchTask = nil,
	hijriDateCache = {},
	menuBar = nil,
	notificationTimer = nil,
	sentNotifications = {},
	settings = utils.deepCopy(DEFAULT_SETTINGS),
	state = {
		cachePath = nil,
		error = nil,
		highlight = false,
		hijriDate = nil,
		lastUpdatedAt = nil,
		location = nil,
		mosque = nil,
		nextPrayer = nil,
		remainingMinutes = nil,
		rows = {},
	},
	timer = nil,
	watcher = nil,
}

local function basename(path)
	if type(path) ~= 'string' then
		return nil
	end

	return path:match '[^/]+$' or path
end

local function trim(value)
	if type(value) ~= 'string' then
		return ''
	end

	return value:match '^%s*(.-)%s*$'
end

local function expandPath(path)
	if type(path) ~= 'string' then
		return path
	end

	return utils.expandPath(path)
end

local function ensureTrailingSlash(path)
	path = expandPath(path)
	if type(path) ~= 'string' or path == '' then
		return hs.fs.temporaryDirectory()
	end

	if path:sub(-1) == '/' then
		return path
	end

	return path .. '/'
end

local function pathExists(path)
	local expanded = expandPath(path)
	return type(expanded) == 'string' and hs.fs.attributes(expanded) ~= nil
end

local function readJson(path)
	path = expandPath(path)
	if not pathExists(path) then
		return nil, 'missing file'
	end

	local ok, data = pcall(hs.json.read, path)
	if not ok then
		return nil, data
	end

	if type(data) ~= 'table' then
		return nil, 'invalid JSON'
	end

	return data, nil
end

local function cachePart(value)
	return trim(value):lower():gsub(' ', '-')
end

local function dateStamp(now)
	return os.date('%d-%m-%Y', now or os.time())
end

local function cachePathForLocation(locationData, now)
	if type(locationData) ~= 'table' then
		return nil
	end

	local city = cachePart(locationData.locality or '')
	local country =
		cachePart(locationData.countryCode or locationData.country or '')

	if city == '' and country == '' then
		return nil
	end

	return ensureTrailingSlash(M.settings.cacheDir)
		.. '.prayer-'
		.. city
		.. '_'
		.. country
		.. '_'
		.. dateStamp(now)
		.. '.json'
end

local function genericCachePath(now)
	return ensureTrailingSlash(M.settings.cacheDir)
		.. '.prayer-'
		.. dateStamp(now)
		.. '.json'
end

local function findCache(now)
	local locationData = readJson(M.settings.locationPath)
	local locationCache = cachePathForLocation(locationData, now)

	if locationCache then
		if pathExists(locationCache) then
			return locationCache, locationData, locationCache
		end

		return nil, locationData, locationCache
	end

	local cachePath = genericCachePath(now)
	if pathExists(cachePath) then
		return cachePath, locationData, cachePath
	end

	return nil, locationData, cachePath
end

local function timingValue(timings, key)
	if type(timings) ~= 'table' then
		return nil
	end

	local titleKey = key:sub(1, 1):upper() .. key:sub(2)
	return timings[key] or timings[titleKey]
end

local function parsePrayerTimestamp(timeString, now)
	local hour, minute = tostring(timeString or ''):match '^(%d%d?):(%d%d)'
	if not hour or not minute then
		return nil
	end

	local parts = os.date('*t', now)
	parts.hour = tonumber(hour)
	parts.min = tonumber(minute)
	parts.sec = 0

	return os.time(parts)
end

local function numberValue(value)
	if type(value) == 'number' then
		return value
	end

	return tonumber(tostring(value or ''):match '%d+')
end

local function normalizeHijriDate(value)
	if type(value) ~= 'table' then
		return nil
	end

	local month = value.month
	local monthNumber = numberValue(month)
	local monthLabel = trim(value.monthLabel or value.monthArabic or '')
	if type(month) == 'table' then
		monthNumber = numberValue(month.number or month.month)
		monthLabel = trim(month.ar or month.arabic or monthLabel)
	end

	local date = {
		day = numberValue(value.day),
		month = monthNumber,
		monthLabel = monthLabel,
		year = numberValue(value.year),
	}

	if not date.day or not date.month or not date.year then
		return nil
	end

	if date.monthLabel == '' then
		date.monthLabel = HIJRI_MONTHS[date.month] or tostring(date.month)
	end

	return date
end

local function appleHijriDate(now)
	local script = string.format(
		[[ObjC.import("Foundation"); const cal=$.NSCalendar.calendarWithIdentifier($.NSCalendarIdentifierIslamicUmmAlQura); const comps=cal.componentsFromDate($.NSCalendarUnitDay|$.NSCalendarUnitMonth|$.NSCalendarUnitYear, $.NSDate.dateWithTimeIntervalSince1970(%d)); JSON.stringify({day:String(comps.day), month:String(comps.month), year:String(comps.year)});]],
		now or os.time()
	)
	local ok, result, err = hs.osascript.javascript(script)
	if not ok or type(result) ~= 'string' then
		log.wf('Failed to resolve Hijri date: %s', tostring(err))
		return nil
	end

	local decodedOk, decoded = pcall(hs.json.decode, result)
	if not decodedOk then
		log.wf('Failed to parse Hijri date: %s', tostring(decoded))
		return nil
	end

	return normalizeHijriDate(decoded)
end

local function hijriDate(now)
	local stamp = dateStamp(now)
	if M.hijriDateCache.stamp == stamp then
		return M.hijriDateCache.date
	end

	local date = appleHijriDate(now)
	M.hijriDateCache = {
		date = date,
		stamp = stamp,
	}
	return date
end

local function hijriDateLabel(date)
	if type(date) ~= 'table' then
		return nil
	end

	return string.format(
		'%s %d %s %dهـ%s',
		RLE,
		date.day,
		date.monthLabel,
		date.year,
		PDF
	)
end

local function buildRows(data, now)
	local timings = data and data.timings or {}
	local rows = {}

	for _, prayer in ipairs(PRAYERS) do
		local timeString = timingValue(timings, prayer.key)
		table.insert(rows, {
			key = prayer.key,
			label = prayer.label,
			arabicLabel = prayer.arabicLabel,
			time = timeString,
			timestamp = parsePrayerTimestamp(timeString, now),
		})
	end

	return rows
end

local function moveFajrAfterIsha(rows, now)
	local fajr = rows[1]
	local isha = rows[#rows]
	if
		fajr
		and fajr.timestamp
		and isha
		and isha.timestamp
		and now > isha.timestamp
	then
		fajr.timestamp = fajr.timestamp + 24 * 60 * 60
	end

	return rows
end

local function nextPrayer(rows, now)
	for _, row in ipairs(rows) do
		if row.timestamp and row.timestamp > now then
			return row, math.floor((row.timestamp - now) / 60)
		end
	end

	return nil, nil
end

local function shouldHighlight(remainingMinutes)
	return remainingMinutes ~= nil
		and remainingMinutes > -1
		and remainingMinutes <= M.settings.warningThresholdMinutes
end

local function styledTitle(title, highlight)
	if highlight then
		return hs.styledtext.new(title, { color = RED })
	end

	return title
end

local function styledMenuText(title, warning, dimmedText)
	local attributes = utils.deepCopy(MENU_TEXT_STYLE)
	if warning then
		attributes.color = RED
	end

	local text = hs.styledtext.new(title, attributes)
	if dimmedText then
		local starts, ends = text:find(dimmedText, 1, true)
		if starts then
			text = text:setStyle({ color = warning and DIM_RED or DIM }, starts, ends)
		end
	end

	return text
end

local function remainingLabel(remainingMinutes)
	if remainingMinutes == nil or remainingMinutes < 0 then
		return nil
	end

	local hours = math.floor(remainingMinutes / 60)
	local minutes = remainingMinutes % 60
	return string.format('(-%02d:%02d)', hours, minutes)
end

local function locationLabel(locationData)
	if type(locationData) ~= 'table' then
		return nil
	end

	local city = trim(locationData.locality or '')
	local country = trim(locationData.countryCode or locationData.country or '')

	if city ~= '' and country ~= '' then
		return city .. ', ' .. country
	end

	if city ~= '' then
		return city
	end

	if country ~= '' then
		return country
	end

	return nil
end

local function prettyMosqueLabel(value)
	local label = trim(value)
	if label == '' then
		return nil
	end

	if
		label:match '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$'
	then
		return nil
	end

	if label:match '^[%w_%-]+$' and label:find '[-_]' then
		label = label:gsub('[-_]+', ' ')
		return label:gsub('(%S)(%S*)', function(first, rest)
			return first:upper() .. rest:lower()
		end)
	end

	return label
end

local function mosqueLabel(data)
	local mosque = data and data.mosque
	if type(mosque) == 'table' then
		local label =
			trim(mosque.label or mosque.name or mosque.associationName or '')
		if label ~= '' then
			return label
		end

		return prettyMosqueLabel(mosque.slug or mosque.uuid or '')
	elseif type(mosque) == 'string' then
		return prettyMosqueLabel(mosque)
	end

	return nil
end

local function menuHeaderLabel(location, mosque)
	if location and mosque then
		return location .. ' · ' .. mosque
	end

	return location or mosque
end

local function tableCount(items)
	local count = 0
	for _ in pairs(items or {}) do
		count = count + 1
	end
	return count
end

local function notificationKey(row)
	if not row.timestamp then
		return nil
	end

	return os.date('%Y-%m-%d', row.timestamp) .. ':' .. row.key
end

local function pruneSentNotifications(now)
	local prefix = os.date('%Y-%m-%d', now) .. ':'
	for key in pairs(M.sentNotifications) do
		if key:sub(1, #prefix) ~= prefix then
			M.sentNotifications[key] = nil
		end
	end
end

local function cancelNotificationTimer()
	if M.notificationTimer then
		M.notificationTimer:stop()
		M.notificationTimer = nil
	end
end

local function sendPrayerNotification(row)
	local key = notificationKey(row)
	if not key or M.sentNotifications[key] then
		return false
	end

	local prayerName = row.arabicLabel or row.label
	local attrs = {
		autoWithdraw = true,
		alwaysPresent = true,
		contentImage = hs.image.imageFromAppBundle 'com.batoulapps.GuidanceMac',
		informativeText = 'حان الان وقت صلاة ' .. prayerName,
		title = prayerName,
	}

	local ok, notification = pcall(hs.notify.new, nil, attrs)
	if not ok or not notification then
		log.ef('Failed to create prayer notification: %s', tostring(notification))
		return false
	end

	notification:send()
	M.sentNotifications[key] = true
	return true
end

local function nextNotificationRow(rows, now)
	local graceSeconds = M.settings.notificationGraceSeconds or 0
	local upcoming = nil

	for _, row in ipairs(rows or {}) do
		local key = notificationKey(row)
		if key and not M.sentNotifications[key] then
			local delaySeconds = row.timestamp - now
			if delaySeconds <= 0 and math.abs(delaySeconds) <= graceSeconds then
				return row, 0
			elseif
				delaySeconds > 0
				and (not upcoming or row.timestamp < upcoming.timestamp)
			then
				upcoming = row
			end
		end
	end

	if upcoming then
		return upcoming, upcoming.timestamp - now
	end

	return nil, nil
end

local function schedulePrayerNotification(rows, now)
	cancelNotificationTimer()
	pruneSentNotifications(now)

	if not M.settings.notificationsEnabled then
		return
	end

	local row, delaySeconds = nextNotificationRow(rows, now)
	if not row then
		return
	end

	if delaySeconds <= 0 then
		if sendPrayerNotification(row) then
			schedulePrayerNotification(rows, os.time())
		end
		return
	end

	M.notificationTimer = hs.timer.doAfter(delaySeconds, function()
		M.notificationTimer = nil
		local elapsedSeconds = os.time() - row.timestamp
		if
			elapsedSeconds >= 0
			and elapsedSeconds <= (M.settings.notificationGraceSeconds or 0)
		then
			sendPrayerNotification(row)
		end
		schedulePrayerNotification(rows, os.time())
	end)
end

local function cacheFetchInProgress(cachePath)
	return M.cacheFetchState.running
		and (not cachePath or M.cacheFetchState.cachePath == cachePath)
end

local function shouldStartCacheFetch(cachePath, force)
	if cacheFetchInProgress() then
		return false
	end

	if type(cachePath) ~= 'string' or cachePath == '' then
		return false
	end

	local cooldown = M.settings.cacheFetchCooldownSeconds or 0
	local lastAttempt = M.cacheFetchState.requestedAt
	if
		not force
		and cooldown > 0
		and lastAttempt
		and M.cacheFetchState.cachePath == cachePath
		and os.time() - lastAttempt < cooldown
	then
		return false
	end

	return true
end

local function recordCacheFetchFailure(cachePath, message)
	local now = os.time()
	M.cacheFetchTask = nil
	M.cacheFetchState = {
		cachePath = cachePath,
		completedAt = now,
		error = message,
		requestedAt = now,
		running = false,
	}
	log.wf('Prayer cache fetch unavailable: %s', message)
end

local function finishCacheFetch(
	cachePath,
	requestedAt,
	exitCode,
	stdout,
	stderr
)
	local output = trim(stdout)
	local err = trim(stderr)
	local errorMessage = nil
	if exitCode ~= 0 then
		errorMessage = err ~= '' and err or ('exit code ' .. tostring(exitCode))
	end

	M.cacheFetchTask = nil
	M.cacheFetchState = {
		cachePath = cachePath,
		completedAt = os.time(),
		error = errorMessage,
		exitCode = exitCode,
		output = output ~= '' and output or nil,
		requestedAt = requestedAt,
		running = false,
	}

	if errorMessage then
		log.wf('Prayer cache fetch failed: %s', errorMessage)
	else
		log.i 'Prayer cache fetch completed'
	end

	if M.menuBar then
		M.update()
	end
end

local function startCacheFetch(cachePath, force)
	if not shouldStartCacheFetch(cachePath, force) then
		return false
	end

	local command = expandPath(M.settings.cacheFetchCommand)
	if type(command) ~= 'string' or command == '' then
		recordCacheFetchFailure(cachePath, 'missing get-prayer command setting')
		return false
	end

	if not pathExists(command) then
		recordCacheFetchFailure(
			cachePath,
			'missing get-prayer command: ' .. command
		)
		return false
	end

	local requestedAt = os.time()
	M.cacheFetchState = {
		cachePath = cachePath,
		requestedAt = requestedAt,
		running = true,
	}

	local shell = expandPath(M.settings.cacheFetchShell or '/bin/zsh')
	local task = hs.task.new(
		shell,
		function(exitCode, stdout, stderr)
			finishCacheFetch(cachePath, requestedAt, exitCode, stdout, stderr)
		end,
		{
			'-lc',
			'exec "$1"',
			'get-prayer',
			command,
		}
	)
	if not task then
		recordCacheFetchFailure(cachePath, 'failed to create get-prayer task')
		return false
	end

	M.cacheFetchTask = task
	local ok, result = pcall(function()
		return task:start()
	end)
	if not ok or result == false then
		recordCacheFetchFailure(
			cachePath,
			'failed to start get-prayer: ' .. tostring(result)
		)
		return false
	end

	log.i 'Fetching missing prayer cache with get-prayer'
	return true
end

local function cancelCacheFetch()
	if M.cacheFetchTask then
		pcall(function()
			M.cacheFetchTask:terminate()
		end)
		M.cacheFetchTask = nil
	end

	M.cacheFetchState.running = false
end

local function resetCacheFetchState()
	M.cacheFetchState = {
		running = false,
	}
end

local function setUnavailable(errorMessage)
	cancelNotificationTimer()
	M.state = {
		cachePath = nil,
		error = errorMessage,
		highlight = false,
		hijriDate = nil,
		lastUpdatedAt = os.time(),
		location = nil,
		mosque = nil,
		nextPrayer = nil,
		remainingMinutes = nil,
		rows = {},
	}

	if M.menuBar then
		M.menuBar:setTitle '--:--'
		M.menuBar:setTooltip('Prayer times unavailable: ' .. errorMessage)
	end
end

local function updateTitle()
	if not M.menuBar then
		return
	end

	if M.state.error or not M.state.nextPrayer then
		M.menuBar:setTitle '--:--'
		return
	end

	local title = (M.state.nextPrayer.arabicLabel or M.state.nextPrayer.label)
		.. ': '
		.. tostring(M.state.nextPrayer.time)

	M.menuBar:setTitle(styledTitle(title, M.state.highlight))
	M.menuBar:setTooltip('Prayer times from ' .. basename(M.state.cachePath))
end

local function prayerMenuItems()
	local items = {}

	local header = menuHeaderLabel(M.state.location, M.state.mosque)
	local hijriLabel = hijriDateLabel(M.state.hijriDate)
	if header then
		table.insert(items, { title = header, disabled = true })
	end
	if hijriLabel then
		table.insert(items, { title = hijriLabel, disabled = true })
	end
	if header or hijriLabel then
		table.insert(items, { title = '-' })
	end

	for _, row in ipairs(M.state.rows or {}) do
		local isNext = M.state.nextPrayer and row.key == M.state.nextPrayer.key
		local timeColumn = row.time or '--:--'
		local remaining = isNext and remainingLabel(M.state.remainingMinutes)
		if remaining then
			timeColumn = timeColumn .. ' ' .. remaining
		end

		local title = table.concat({ row.label, timeColumn, row.arabicLabel }, '\t')
		table.insert(items, {
			disabled = not isNext,
			checked = isNext,
			title = styledMenuText(title, isNext and M.state.highlight, remaining),
		})
	end

	return items
end

local function metadataMenuItems()
	local items = {
		{ title = '-' },
	}

	if M.state.lastUpdatedAt then
		table.insert(items, {
			title = 'Updated ' .. os.date('%H:%M', M.state.lastUpdatedAt),
			disabled = true,
		})
	end

	if M.state.cachePath then
		table.insert(items, {
			title = 'Cache: ' .. basename(M.state.cachePath),
			disabled = true,
		})
	end

	return items
end

local function relevantPathChanged(files)
	for _, path in ipairs(files or {}) do
		local file = basename(path)
		if file == '.location.json' or file:match '^%.prayer%-.*%.json$' then
			return true
		end
	end

	return false
end

function M.update(opts)
	opts = type(opts) == 'table' and opts or {}

	local now = os.time()
	local cachePath, locationData, expectedCachePath = findCache(now)

	if not cachePath then
		local fetching = cacheFetchInProgress(expectedCachePath)
		if not fetching then
			fetching = startCacheFetch(expectedCachePath, opts.forceFetch)
		end
		if not fetching then
			fetching = cacheFetchInProgress()
		end

		local message = 'no prayer cache for ' .. dateStamp(now)
		if fetching then
			message = message .. '; fetching with get-prayer'
		end

		setUnavailable(message)
		return false
	end

	local data, err = readJson(cachePath)
	if not data then
		setUnavailable(
			'failed to read ' .. basename(cachePath) .. ': ' .. tostring(err)
		)
		return false
	end

	local rows = moveFajrAfterIsha(buildRows(data, now), now)
	local mosque = mosqueLabel(data)
	local hijri = hijriDate(now)
	local upcoming, remaining = nextPrayer(rows, now)
	if not upcoming then
		setUnavailable('no upcoming prayer in ' .. basename(cachePath))
		return false
	end

	M.state = {
		cachePath = cachePath,
		error = nil,
		highlight = shouldHighlight(remaining),
		hijriDate = hijri,
		lastUpdatedAt = now,
		location = locationLabel(locationData),
		mosque = mosque,
		nextPrayer = upcoming,
		remainingMinutes = remaining,
		rows = rows,
	}

	updateTitle()
	schedulePrayerNotification(rows, now)
	return true
end

function M.menu()
	M.update()

	if M.state.error then
		return {
			{ title = 'Prayer times unavailable', disabled = true },
			{ title = M.state.error, disabled = true },
			{ title = '-' },
			{
				title = 'Refresh',
				fn = function()
					M.update { forceFetch = true }
				end,
			},
		}
	end

	local items = prayerMenuItems()
	for _, item in ipairs(metadataMenuItems()) do
		table.insert(items, item)
	end
	table.insert(items, { title = '-' })
	table.insert(items, {
		title = 'Refresh',
		fn = function()
			M.update { forceFetch = true }
		end,
	})

	return items
end

function M.getStatus()
	return {
		cacheFetch = utils.deepCopy(M.cacheFetchState),
		cachePath = M.state.cachePath,
		error = M.state.error,
		highlight = M.state.highlight,
		hijriDate = utils.deepCopy(M.state.hijriDate),
		lastUpdatedAt = M.state.lastUpdatedAt,
		location = M.state.location,
		mosque = M.state.mosque,
		nextPrayer = utils.deepCopy(M.state.nextPrayer),
		notificationScheduled = M.notificationTimer ~= nil,
		notificationsEnabled = M.settings.notificationsEnabled,
		remainingMinutes = M.state.remainingMinutes,
		rowCount = #(M.state.rows or {}),
		sentNotificationCount = tableCount(M.sentNotifications),
	}
end

local function startWatcher()
	if M.watcher then
		M.watcher:stop()
		M.watcher = nil
	end

	local cacheDir = ensureTrailingSlash(M.settings.cacheDir)
	if not pathExists(cacheDir) then
		log.wf('Prayer cache directory does not exist: %s', cacheDir)
		return false
	end

	M.watcher = hs.pathwatcher.new(cacheDir, function(files)
		if not relevantPathChanged(files) then
			return
		end

		utils.debounce('prayer.update', 0.5, M.update)
	end)
	M.watcher:start()
	return true
end

local function startTimer()
	if M.timer then
		M.timer:stop()
		M.timer = nil
	end

	M.timer = hs.timer.doEvery(M.settings.refreshIntervalSeconds, M.update)
	return M.timer ~= nil
end

function M.setup()
	cancelCacheFetch()
	resetCacheFetchState()
	M.settings = utils.deepCopy(DEFAULT_SETTINGS)

	if M.menuBar then
		M.menuBar:delete()
		M.menuBar = nil
	end

	M.menuBar = hs.menubar.new(true, M.settings.autosaveName)
	if not M.menuBar then
		log.e 'Unable to create prayer times menubar item'
		return false
	end

	M.menuBar:setTooltip 'Prayer times'
	M.menuBar:setMenu(M.menu)

	M.update()
	startTimer()
	startWatcher()

	return true
end

function M.stop()
	if M.timer then
		M.timer:stop()
		M.timer = nil
	end

	if M.watcher then
		M.watcher:stop()
		M.watcher = nil
	end

	cancelNotificationTimer()
	cancelCacheFetch()

	if M.menuBar then
		M.menuBar:delete()
		M.menuBar = nil
	end

	utils.cancelDebounce 'prayer.update'
end

return M
