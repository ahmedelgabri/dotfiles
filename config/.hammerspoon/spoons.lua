local log = require 'log'
local utils = require 'utils'

local M = {}

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

local function resolveDefaultBrowser(settings)
	for _, appKey in
		ipairs(settings.urls and settings.urls.defaultBrowserPriority or {})
	do
		local bundleID = utils.getAppBundleID(appKey)
		if bundleID then
			return bundleID
		end
	end

	return utils.getAppBundleID 'safari'
end

local function resolveRuleTarget(target)
	if type(target) ~= 'string' then
		return target
	end

	return utils.getAppBundleID(target) or target
end

local function buildDispatchRules(settings)
	local rules = {}
	for _, rule in ipairs(settings.urls and settings.urls.dispatchRules or {}) do
		local target = resolveRuleTarget(rule[2])
		if target then
			table.insert(rules, { rule[1], target, rule[3], rule[4] })
		else
			log.wf(
				"Skipping URL dispatch rule '%s' because target app is missing",
				tostring(rule[1])
			)
		end
	end
	return rules
end

local function buildRedirectDecoders(settings)
	local decoders = {}
	for _, decoder in
		ipairs(settings.urls and settings.urls.redirectDecoders or {})
	do
		table.insert(decoders, decoder)
	end
	return decoders
end

function M.buildURLDispatcherConfig(settings)
	local defaultHandler = resolveDefaultBrowser(settings)
	if not defaultHandler then
		log.w 'Skipping URLDispatcher setup because no default browser could be resolved'
		return nil
	end

	return {
		start = true,
		config = {
			default_handler = defaultHandler,
			decode_slack_redir_urls = true,
			set_system_handler = settings.features
					and settings.features.setSystemBrowserHandler
				or false,
			url_patterns = buildDispatchRules(settings),
			url_redir_decoders = buildRedirectDecoders(settings),
		},
	}
end

function M.updateSpoons()
	if not M.install then
		log.w 'SpoonInstall is not available'
		return false
	end

	M.install:updateAllRepos()
	return true
end

function M.setup(settings)
	if not loadSpoon 'SpoonInstall' then
		return false
	end

	M.install = spoon.SpoonInstall

	if settings.spoons and settings.spoons.loadEmmyLua then
		M.install:andUse 'EmmyLua'
	end

	M.install:andUse('Caffeine', {
		start = true,
	})

	local urlDispatcherConfig = M.buildURLDispatcherConfig(settings)
	if urlDispatcherConfig then
		M.install:andUse('URLDispatcher', urlDispatcherConfig)
		if spoon.URLDispatcher and spoon.URLDispatcher.logger then
			spoon.URLDispatcher.logger.setLogLevel(
				settings.spoons and settings.spoons.urlDispatcherLogLevel or 'warning'
			)
		end
	end

	return true
end

return M
