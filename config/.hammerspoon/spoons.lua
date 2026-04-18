local log = require 'log'
local utils = require 'utils'

local DEFAULT_URL_DISPATCH_RULES = {
	{ 'https?://%w+.zoom.us/j/', 'zoom' },
}

local DEFAULT_URL_REDIRECT_DECODERS = {
	{
		'redirect old NixOS wiki',
		'https://nixos%.wiki/(.*)',
		'https://wiki.nixos.org/%1',
	},
}

local MANAGED_SPOONS = {
	'EmmyLua',
	'Caffeine',
	'URLDispatcher',
}

local DEFAULT_SETTINGS = {
	urlDispatcher = {
		enabled = true,
		start = true,
		default_handler = nil,
		decode_slack_redir_urls = true,
		set_system_handler = true,
		url_patterns = DEFAULT_URL_DISPATCH_RULES,
		url_redir_decoders = DEFAULT_URL_REDIRECT_DECODERS,
		log_level = 'warning',
	},
}

local M = {
	install = nil,
	settings = utils.deepCopy(DEFAULT_SETTINGS),
	setupComplete = false,
}

local function loadSpoon(name)
	local ok, err = pcall(hs.loadSpoon, name)
	if not ok then
		log.ef("Failed to load spoon '%s': %s", name, err)
		return false
	end

	if not spoon[name] then
		log.ef("Spoon '%s' is unavailable after loading", name)
		return false
	end

	return true
end

local function resolveHandlerTarget(target)
	if type(target) ~= 'string' then
		return target
	end

	local bundleID = utils.getAppBundleID(target)
	if bundleID then
		return bundleID
	end

	if target:find('.', 1, true) then
		return target
	end

	return nil
end

local function resolveDefaultBrowser()
	local configured = resolveHandlerTarget(
		M.settings.urlDispatcher.default_handler
	)
	if configured then
		return configured
	end

	local bundleID = utils.resolvePreferredBrowser()
	if bundleID then
		return bundleID
	end

	return utils.getAppBundleID 'safari'
end

local function buildDispatchRules(rules)
	local resolvedRules = {}
	for _, rule in ipairs(rules or {}) do
		local target = resolveHandlerTarget(rule[2])
		if target or rule[3] then
			table.insert(resolvedRules, { rule[1], target, rule[3], rule[4] })
		else
			log.wf(
				"Skipping URL dispatch rule '%s' because target app is missing",
				tostring(rule[1])
			)
		end
	end
	return resolvedRules
end

local function mergeURLDispatcherListField(name, base, overrides)
	if overrides == nil then
		return utils.deepCopy(base or {})
	end

	if type(overrides) ~= 'table' then
		log.wf(
			"Ignoring invalid URLDispatcher %s override of type '%s'",
			name,
			type(overrides)
		)
		return utils.deepCopy(base or {})
	end

	local merged = {}
	for _, item in ipairs(overrides) do
		table.insert(merged, utils.deepCopy(item))
	end
	for _, item in ipairs(base or {}) do
		table.insert(merged, utils.deepCopy(item))
	end
	return merged
end

local function mergeURLDispatcherConfig(base, overrides)
	local merged = utils.deepMerge(base or {}, overrides or {})
	if type(overrides) ~= 'table' then
		return merged
	end

	if overrides.url_patterns ~= nil then
		merged.url_patterns = mergeURLDispatcherListField(
			'url_patterns',
			base and base.url_patterns,
			overrides.url_patterns
		)
	end

	if overrides.url_redir_decoders ~= nil then
		merged.url_redir_decoders = mergeURLDispatcherListField(
			'url_redir_decoders',
			base and base.url_redir_decoders,
			overrides.url_redir_decoders
		)
	end

	return merged
end

local function stopURLDispatcherPatternWatchers()
	if not spoon.URLDispatcher then
		return
	end

	for _, watcher in pairs(spoon.URLDispatcher.pat_watchers or {}) do
		if watcher then
			watcher:stop()
		end
	end

	spoon.URLDispatcher.pat_watchers = {}
	spoon.URLDispatcher.pat_files = {}
end

function M.getURLDispatcherConfig()
	return utils.deepCopy(M.settings.urlDispatcher)
end

function M.buildURLDispatcherConfig()
	local settings = M.settings.urlDispatcher or {}
	if settings.enabled == false then
		return nil
	end

	local defaultHandler = resolveDefaultBrowser()
	if not defaultHandler then
		log.w 'Skipping URLDispatcher setup because no default browser could be resolved'
		return nil
	end

	return {
		start = settings.start ~= false,
		log_level = settings.log_level,
		config = {
			default_handler = defaultHandler,
			decode_slack_redir_urls = settings.decode_slack_redir_urls ~= false,
			set_system_handler = settings.set_system_handler ~= false,
			url_patterns = buildDispatchRules(settings.url_patterns),
			url_redir_decoders = utils.deepCopy(
				settings.url_redir_decoders or {}
			),
		},
	}
end

function M.getEffectiveURLDispatcherConfig()
	return utils.deepCopy(M.buildURLDispatcherConfig())
end

function M.getStatus()
	local runtime = M.buildURLDispatcherConfig()
	if not runtime then
		return {
			setupComplete = M.setupComplete,
			urlDispatcher = {
				enabled = false,
			},
		}
	end

	return {
		setupComplete = M.setupComplete,
		urlDispatcher = {
			decodeSlackRedirURLs = runtime.config.decode_slack_redir_urls,
			decoderCount = #(runtime.config.url_redir_decoders or {}),
			defaultHandler = runtime.config.default_handler,
			enabled = true,
			logLevel = runtime.log_level,
			ruleCount = #(runtime.config.url_patterns or {}),
			setSystemHandler = runtime.config.set_system_handler,
			start = runtime.start,
		},
	}
end

function M.applyURLDispatcherConfig()
	local runtime = M.buildURLDispatcherConfig()
	if not runtime then
		if spoon.URLDispatcher then
			stopURLDispatcherPatternWatchers()
			hs.urlevent.httpCallback = nil
		end
		return true
	end

	if not spoon.URLDispatcher and not loadSpoon 'URLDispatcher' then
		return false
	end

	stopURLDispatcherPatternWatchers()

	for key, value in pairs(runtime.config) do
		spoon.URLDispatcher[key] = value
	end

	if spoon.URLDispatcher.logger and runtime.log_level then
		spoon.URLDispatcher.logger.setLogLevel(runtime.log_level)
	end

	if runtime.start == false then
		hs.urlevent.httpCallback = nil
		return true
	end

	spoon.URLDispatcher:start()
	return true
end

function M.configureURLDispatcher(overrides)
	M.settings.urlDispatcher = mergeURLDispatcherConfig(
		M.settings.urlDispatcher,
		overrides or {}
	)

	if M.setupComplete then
		return M.applyURLDispatcherConfig()
	end

	return true
end

function M.setURLDispatcherConfig(config)
	M.settings.urlDispatcher = utils.deepCopy(config or {})

	if M.setupComplete then
		return M.applyURLDispatcherConfig()
	end

	return true
end

function M.resetURLDispatcherConfig()
	return M.setURLDispatcherConfig(DEFAULT_SETTINGS.urlDispatcher)
end

function M.updateSpoons()
	if not M.install then
		log.w 'SpoonInstall is not available'
		return false
	end

	M.install:updateAllRepos()

	local updated = true
	for _, spoonName in ipairs(MANAGED_SPOONS) do
		local ok = M.install:installSpoonFromRepo(spoonName)
		if ok then
			log.i(string.format("Updated spoon '%s'", spoonName))
		else
			updated = false
			log.wf("Failed to update spoon '%s'", spoonName)
		end
	end

	return updated
end

function M.setup()
	if not loadSpoon 'SpoonInstall' then
		return false
	end

	M.install = spoon.SpoonInstall
	M.updateSpoons()

	M.install:andUse 'EmmyLua'

	M.install:andUse('Caffeine', {
		start = true,
	})

	M.setupComplete = true
	return M.applyURLDispatcherConfig()
end

return M
