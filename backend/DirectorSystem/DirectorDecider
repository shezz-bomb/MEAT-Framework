-- DirectorDecider.lua (corregido - sin booleanos en aritmética)

local DirectorDecider = {}
local DirectorMemory = require(script.Parent.DirectorMemory)

local EVENT_COOLDOWNS = {
	MeatMeteor        = 120,
	CypherStorm       = 90,
	BountyOnTopPlayer = 150,
	GravitalPatrol    = 180,
	QuArrival         = 300,
	SilenceZone       = 100,
	HunterParty       = 140,
	MeatRain          = 110,
	ReverseGravity    = 130,
	CarnageRitual     = 200,
}

local lastExecuted = {}

local function onCooldown(name)
	local last = lastExecuted[name]
	if not last then return false end
	return (tick() - last) < (EVENT_COOLDOWNS[name] or 60)
end

local function getMetric(metrics, key, default)
	local val = metrics[key]
	if type(val) == "boolean" then return default end
	if val == nil then return default end
	return val
end

local function shouldAvoid(eventName, metrics)
	if DirectorMemory:hasHappenedRecentlySeconds(eventName, 45) then
		return true
	end
	if DirectorMemory:isOnStreak(eventName, 2) then
		return true
	end
	return false
end

local EVENT_OPTIONS = {
	{
		name = "MeatMeteor",
		condition = function(metrics, anger)
			if onCooldown("MeatMeteor") or shouldAvoid("MeatMeteor", metrics) then return 0 end
			local timeFactor = math.min(metrics.timeSinceLastEvent / 30, 2)
			local killBonus = getMetric(metrics, "globalKillRate", 0) * 0.5
			return 10 + (timeFactor * 15) + (metrics.totalPlayers * 5) + killBonus
		end
	},
	{
		name = "CypherStorm",
		condition = function(metrics, anger)
			if onCooldown("CypherStorm") or shouldAvoid("CypherStorm", metrics) then return 0 end
			local base = metrics.totalPlayers > 0 and (anger * 0.4 + 5) or 0
			local cypherBonus = getMetric(metrics, "cypherUsageRate", 0) * 10
			if DirectorMemory:getCurrentDay() == "SABADO_DEL_CIFRADO" then
				return (80 + anger + cypherBonus) * 1.5
			end
			return base + cypherBonus
		end
	},
	{
		name = "BountyOnTopPlayer",
		condition = function(metrics, anger)
			if onCooldown("BountyOnTopPlayer") or shouldAvoid("BountyOnTopPlayer", metrics) then return 0 end
			if metrics.topPlayerKills < 3 then return 0 end
			local streakBonus = getMetric(metrics, "topPlayerStreak", 0) * 3
			return metrics.topPlayerKills * 8 + streakBonus + (anger * 0.5)
		end
	},
	{
		name = "GravitalPatrol",
		condition = function(metrics, anger)
			if onCooldown("GravitalPatrol") or shouldAvoid("GravitalPatrol", metrics) then return 0 end
			local count = metrics.speciesCount["ToolBreeder"] or 0
			local healthBonus = (getMetric(metrics, "averageHealth", 100) < 50) and 20 or 0
			return count * 12 + (anger * 0.2) + healthBonus
		end
	},
	{
		name = "QuArrival",
		condition = function(metrics, anger)
			if onCooldown("QuArrival") or shouldAvoid("QuArrival", metrics) then return 0 end
			if not DirectorMemory:isHolyDay() then return 0 end
			local chaos = DirectorMemory:getChaosMultiplier()
			local killBonus = getMetric(metrics, "globalKillRate", 0) * 15
			local streakBonus = getMetric(metrics, "highestStreak", 0) * 5
			return (anger * 1.5 + 20 + killBonus + streakBonus) * chaos
		end
	},
	{
		name = "SilenceZone",
		condition = function(metrics, anger)
			if onCooldown("SilenceZone") or shouldAvoid("SilenceZone", metrics) then return 0 end
			local cypherUsage = getMetric(metrics, "cypherUsageRate", 0)
			return cypherUsage * 15 + anger * 0.3
		end
	},
	{
		name = "HunterParty",
		condition = function(metrics, anger)
			if onCooldown("HunterParty") or shouldAvoid("HunterParty", metrics) then return 0 end
			local topStreak = getMetric(metrics, "topPlayerStreak", 0)
			local killRateBonus = getMetric(metrics, "globalKillRate", 0) * 2
			local base = 0
			if topStreak >= 8 then base = 60
			elseif topStreak >= 5 then base = 30
			else base = 0 end
			return base + killRateBonus
		end
	},
	{
		name = "MeatRain",
		condition = function(metrics, anger)
			if onCooldown("MeatRain") or shouldAvoid("MeatRain", metrics) then return 0 end
			return anger * 0.5 + (metrics.totalPlayers * 2) + (getMetric(metrics, "globalKillRate", 0) * 3)
		end
	},
	{
		name = "ReverseGravity",
		condition = function(metrics, anger)
			if onCooldown("ReverseGravity") or shouldAvoid("ReverseGravity", metrics) then return 0 end
			local lowHealth = (getMetric(metrics, "averageHealth", 100) < 40) and 40 or 0
			return lowHealth + anger * 0.4
		end
	},
	{
		name = "CarnageRitual",
		condition = function(metrics, anger)
			if onCooldown("CarnageRitual") or shouldAvoid("CarnageRitual", metrics) then return 0 end
			local killRate = getMetric(metrics, "globalKillRate", 0)
			local duelBonus = getMetric(metrics, "totalActiveDuels", 0) * 5
			local base = (killRate > 3) and (anger * 0.8) or 0
			return base + duelBonus
		end
	},
}

local function weightedSelect(options, context)
	local candidates = {}
	local totalWeight = 0
	for _, opt in ipairs(options) do
		local score = opt.condition(context.metrics, context.anger)
		if type(score) == "number" and score > 0 then
			table.insert(candidates, { opt = opt, score = score })
			totalWeight = totalWeight + score
		end
	end
	if totalWeight <= 0 or #candidates == 0 then return nil, 0 end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, c in ipairs(candidates) do
		cumulative = cumulative + c.score
		if roll <= cumulative then
			return c.opt, c.score
		end
	end
	return candidates[#candidates].opt, candidates[#candidates].score
end

function DirectorDecider:decide(metrics, anger)
	local context = { metrics = metrics, anger = anger }
	local best, score = weightedSelect(EVENT_OPTIONS, context)
	if not best or score <= 0 then return nil end
	lastExecuted[best.name] = tick()
	print(string.format("👁️ Director decidió: %s (score: %.1f | anger: %.1f)", best.name, score, anger))
	return best.name
end

return DirectorDecider
