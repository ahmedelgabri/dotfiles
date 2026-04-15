local log = require 'log'
local utils = require 'utils'

local DEFAULT_BROWSER_PRIORITY = {
	'firefox',
	'chrome',
	'safari',
}

local URL_DISPATCH_RULES = {
	{ 'https?://%w+.zoom.us/j/', 'zoom' },
}

local URL_REDIRECT_DECODERS = {
	{
		'redirect old NixOS wiki',
		'https://nixos%.wiki/(.*)',
		'https://wiki.nixos.org/%1',
	},
}

local MANAGED_SPOONS = {
	'Caffeine',
	'URLDispatcher',
}

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

local function resolveDefaultBrowser()
	for _, appKey in ipairs(DEFAULT_BROWSER_PRIORITY) do
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

local function buildDispatchRules()
	local rules = {}
	for _, rule in ipairs(URL_DISPATCH_RULES) do
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

local function buildRedirectDecoders()
	local decoders = {}
	for _, decoder in ipairs(URL_REDIRECT_DECODERS) do
		table.insert(decoders, decoder)
	end
	return decoders
end

function M.buildURLDispatcherConfig()
	local defaultHandler = resolveDefaultBrowser()
	if not defaultHandler then
		log.w 'Skipping URLDispatcher setup because no default browser could be resolved'
		return nil
	end

	return {
		start = true,
		config = {
			default_handler = defaultHandler,
			decode_slack_redir_urls = true,
			set_system_handler = true,
			url_patterns = buildDispatchRules(),
			url_redir_decoders = buildRedirectDecoders(),
		},
	}
end

local function upgradeManagedSpoons()
	if not M.install then
		log.w 'SpoonInstall is not available'
		return false
	end

	M.install:updateAllRepos()

	local spoonsToUpgrade = utils.deepCopy(MANAGED_SPOONS)
	if LOAD_EMMY_LUA then
		table.insert(spoonsToUpgrade, 'EmmyLua')
	end

	local updated = true
	for _, spoonName in ipairs(spoonsToUpgrade) do
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

function M.updateSpoons()
	return upgradeManagedSpoons()
end

function M.setup()
	if not loadSpoon 'SpoonInstall' then
		return false
	end

	M.install = spoon.SpoonInstall
	upgradeManagedSpoons()

	M.install:andUse 'EmmyLua'

	M.install:andUse('Caffeine', {
		start = true,
	})

	local urlDispatcherConfig = M.buildURLDispatcherConfig()
	if urlDispatcherConfig then
		M.install:andUse('URLDispatcher', urlDispatcherConfig)
		if spoon.URLDispatcher and spoon.URLDispatcher.logger then
			spoon.URLDispatcher.logger.setLogLevel 'warning'
		end
	end

	return true
end

return M
