-- DirectorMonitor — MEAT Project (versión BESTIA)
-- Solo recalcula en eventos gatillados (rotación de slots, kills, uso de poderes, duelos).
-- NUNCA usa Heartbeat.
-- Proporciona métricas avanzadas y un sistema de ira reactivo.

local DirectorMonitor = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==================== ESTADO INTERNO ====================
local state = {
	angerLevel = 0,
	lastEventTime = 0,
	lastRecalcTime = 0,
	metrics = {},
	-- Historial de métricas (últimos 5 valores para detectar tendencias)
	metricHistory = {},
	-- Contadores para calcular tasas
	lastTotalKills = 0,
	lastTotalCypherUses = 0,
	lastTotalDuels = 0,
	lastTimestamp = 0,
}

-- ==================== CONFIGURACIÓN ====================
local ANGER_CONFIG = {
	HEALTH_FACTOR_MAX = 50,      -- 50 puntos si salud media es 0
	TIME_FACTOR_MAX = 50,        -- 50 puntos si han pasado 5 minutos sin evento
	DOMINANCE_FACTOR_MAX = 60,   -- 60 puntos si una especie >80%
	BOREDOM_FACTOR_MAX = 30,     -- 30 puntos si hay menos de 3 jugadores
	KILL_RATE_FACTOR_MAX = 40,   -- 40 puntos si kill rate > 10 por minuto
	CYPHER_USAGE_FACTOR_MAX = 30, -- 30 puntos si uso de poderes es alto
	STREAK_FACTOR_MAX = 35,      -- 35 puntos si hay rachas altas
	DUEL_FACTOR_MAX = 25,        -- 25 puntos si hay muchos duelos activos
}

-- ==================== MÉTRICAS AVANZADAS ====================

function DirectorMonitor:getMetrics()
	local now = tick()
	local timeDelta = math.max(0.1, now - state.lastRecalcTime)

	local metrics = {
		totalPlayers = 0,
		averageHealth = 0,
		speciesCount = {},
		timeSinceLastEvent = tick() - state.lastEventTime,
		topPlayer = nil,
		topPlayerKills = 0,
		topPlayerStreak = 0,
		noobPlayers = {},
		-- Nuevas métricas
		globalKillRate = 0,
		cypherUsageRate = 0,
		avgStreak = 0,
		totalActiveDuels = 0,
		highestStreak = 0,
		dominantSpecies = nil,
		dominanceRatio = 0,
	}

	local healthSum = 0
	local playerCount = 0
	local totalKills = 0
	local totalStreaks = 0
	local totalCypherUses = 0
	local totalActiveDuels = 0

	-- Recopilar datos de todos los jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChildOfClass("Humanoid") then
			local hum = char:FindFirstChildOfClass("Humanoid")
			healthSum += hum.Health
			playerCount += 1

			local species = player:GetAttribute("Species") or "StarPerson"
			metrics.speciesCount[species] = (metrics.speciesCount[species] or 0) + 1

			local kills = player:GetAttribute("Kills") or 0
			local streak = player:GetAttribute("Streak") or 0
			local cypherUses = player:GetAttribute("CypherUses") or 0  -- necesitas incrementar esto en CypherManager

			totalKills += kills
			totalStreaks += streak
			totalCypherUses += cypherUses

			if kills > metrics.topPlayerKills then
				metrics.topPlayerKills = kills
				metrics.topPlayer = player
				metrics.topPlayerStreak = streak
			end

			if streak > metrics.highestStreak then
				metrics.highestStreak = streak
			end

			if kills <= 2 then
				table.insert(metrics.noobPlayers, player)
			end

			-- Detectar duelos activos (si tu sistema tiene un atributo o Remote)
			if player:GetAttribute("InDuel") then
				totalActiveDuels += 1
			end
		end
	end

	metrics.totalPlayers = playerCount
	metrics.averageHealth = playerCount > 0 and healthSum / playerCount or 100
	metrics.avgStreak = playerCount > 0 and totalStreaks / playerCount or 0
	metrics.totalActiveDuels = totalActiveDuels

	-- Calcular tasas (kills y cypher uses por segundo, luego convertimos a por minuto)
	if state.lastTimestamp > 0 and timeDelta > 0 then
		local killsDelta = totalKills - state.lastTotalKills
		local cypherDelta = totalCypherUses - state.lastTotalCypherUses
		local duelsDelta = totalActiveDuels - state.lastTotalDuels

		metrics.globalKillRate = (killsDelta / timeDelta) * 60  -- kills por minuto
		metrics.cypherUsageRate = (cypherDelta / timeDelta) * 60
		-- Para duelos no necesitamos tasa, solo el valor actual
	end

	-- Actualizar estado para la próxima vez
	state.lastTotalKills = totalKills
	state.lastTotalCypherUses = totalCypherUses
	state.lastTotalDuels = totalActiveDuels
	state.lastTimestamp = now
	state.lastRecalcTime = now

	-- Identificar especie dominante
	local maxCount = 0
	for species, count in pairs(metrics.speciesCount) do
		if count > maxCount then
			maxCount = count
			metrics.dominantSpecies = species
		end
	end
	if playerCount > 0 then
		metrics.dominanceRatio = maxCount / playerCount
	end

	-- Guardar métricas en el estado
	state.metrics = metrics

	-- Guardar en historial (para detectar tendencias)
	table.insert(state.metricHistory, { 
		time = now, 
		killRate = metrics.globalKillRate,
		anger = state.angerLevel,
		averageHealth = metrics.averageHealth
	})
	-- Mantener solo los últimos 10 registros
	while #state.metricHistory > 10 do table.remove(state.metricHistory, 1) end

	return metrics
end

-- ==================== CÁLCULO DE IRA (MEJORADO) ====================

function DirectorMonitor:calculateAnger()
	local metrics = self:getMetrics()

	-- 1. Factor de salud (cuanta menos salud media, más ira)
	local healthFactor = (100 - metrics.averageHealth) * (ANGER_CONFIG.HEALTH_FACTOR_MAX / 100)

	-- 2. Factor de tiempo sin eventos (aburrimiento del Director)
	local timeSinceLast = math.min(metrics.timeSinceLastEvent, 300) -- máx 5 min
	local timeFactor = (timeSinceLast / 300) * ANGER_CONFIG.TIME_FACTOR_MAX

	-- 3. Factor de dominancia de especie (si una especie >60% del lobby)
	local dominanceFactor = 0
	if metrics.dominanceRatio > 0.6 then
		local excess = metrics.dominanceRatio - 0.6
		dominanceFactor = math.min(excess * 100, 1) * ANGER_CONFIG.DOMINANCE_FACTOR_MAX
	end

	-- 4. Factor de aburrimiento (pocos jugadores)
	local boredomFactor = 0
	if metrics.totalPlayers < 3 then
		boredomFactor = ANGER_CONFIG.BOREDOM_FACTOR_MAX
	elseif metrics.totalPlayers < 5 then
		boredomFactor = ANGER_CONFIG.BOREDOM_FACTOR_MAX * 0.5
	end

	-- 5. Factor de ritmo de muertes (kill rate alto = más ira)
	local killRateFactor = 0
	if metrics.globalKillRate > 0 then
		killRateFactor = math.min(metrics.globalKillRate / 10, 1) * ANGER_CONFIG.KILL_RATE_FACTOR_MAX
	end

	-- 6. Factor de uso de poderes (cypher usage alto = Director se altera)
	local cypherFactor = 0
	if metrics.cypherUsageRate > 0 then
		cypherFactor = math.min(metrics.cypherUsageRate / 20, 1) * ANGER_CONFIG.CYPHER_USAGE_FACTOR_MAX
	end

	-- 7. Factor de rachas (si alguien tiene streak >5, enfada al Director)
	local streakFactor = 0
	if metrics.highestStreak >= 10 then
		streakFactor = ANGER_CONFIG.STREAK_FACTOR_MAX
	elseif metrics.highestStreak >= 5 then
		streakFactor = ANGER_CONFIG.STREAK_FACTOR_MAX * 0.6
	elseif metrics.highestStreak >= 3 then
		streakFactor = ANGER_CONFIG.STREAK_FACTOR_MAX * 0.3
	end

	-- 8. Factor de duelos (si hay muchos duelos, al Director le gusta el caos)
	local duelFactor = math.min(metrics.totalActiveDuels, 5) / 5 * ANGER_CONFIG.DUEL_FACTOR_MAX

	-- Sumar todos los factores
	local anger = healthFactor + timeFactor + dominanceFactor + boredomFactor 
		+ killRateFactor + cypherFactor + streakFactor + duelFactor

	-- Aplicar modificador por día santo (desde DirectorMemory)
	local DirectorMemory = require(script.Parent.DirectorMemory)
	local chaosMult = DirectorMemory:getChaosMultiplier()
	anger = anger * chaosMult

	-- Clampear entre 0 y 100
	state.angerLevel = math.clamp(anger, 0, 100)

	-- Depuración (opcional, puedes comentar)
	-- print(string.format("📊 Anger: %.1f | health=%.1f time=%.1f dom=%.1f kills=%.1f cypher=%.1f streak=%.1f duel=%.1f", 
	--	state.angerLevel, healthFactor, timeFactor, dominanceFactor, killRateFactor, cypherFactor, streakFactor, duelFactor))

	return state.angerLevel
end

-- ==================== MÉTODOS PARA EVENTOS ====================

-- Se llama cuando ocurre una rotación de slots (desde CypherManager)
function DirectorMonitor:onSlotRotation()
	self:getMetrics()  -- Actualiza métricas
	self:calculateAnger() -- Recalcula ira
	local CalendarService = require(script.Parent.CalendarService.CalendarService)

	local metrics = state.metrics
	-- Penalizar al dominante
	if metrics.topPlayer then
		CalendarService:punishDominant(metrics.topPlayer, metrics.topPlayerKills)
	end
	-- Premiar a noobs
	for _, noob in ipairs(metrics.noobPlayers) do
		CalendarService:rewardNoob(noob, noob:GetAttribute("Kills") or 0)
	end
end

-- Se llama cuando un jugador usa un Cypher (debes llamarlo desde CypherManager)
function DirectorMonitor:onCypherUsed(player)
	-- Incrementar contador de uso de poderes (atributo)
	local current = player:GetAttribute("CypherUses") or 0
	player:SetAttribute("CypherUses", current + 1)
	-- No recalculamos ira aquí para no sobrecargar, se recalculará en la próxima rotación o muerte
end

-- Se llama cuando ocurre una muerte (debes llamarlo desde CombatManager)
function DirectorMonitor:onKill(killer, victim)
	-- Actualizar métricas de kills (ya se maneja con atributos)
	-- Recalcular ira inmediatamente para que el Director reaccione rápido
	self:calculateAnger()
end

-- Se llama cuando un jugador entra en duelo
function DirectorMonitor:onDuelStart(player)
	player:SetAttribute("InDuel", true)
	self:calculateAnger()
end

function DirectorMonitor:onDuelEnd(player)
	player:SetAttribute("InDuel", nil)
	self:calculateAnger()
end

-- Reportar que un evento del Director ha ocurrido
function DirectorMonitor:reportEvent(eventType)
	state.lastEventTime = tick()
	-- Recalcular ira después de un evento (el enfado se reduce)
	self:calculateAnger()
end

-- ==================== MÉTODOS PARA CONSULTA EXTERNA ====================

-- Obtener el nivel actual de ira (sin recalcular)
function DirectorMonitor:getCurrentAnger()
	return state.angerLevel
end

-- Obtener las métricas más recientes (sin recalcular)
function DirectorMonitor:getCurrentMetrics()
	return state.metrics
end

-- Obtener historial de métricas (para tendencias)
function DirectorMonitor:getMetricHistory()
	return state.metricHistory
end

-- Forzar una recalibración completa (útil para debugging)
function DirectorMonitor:forceRecalculation()
	self:getMetrics()
	self:calculateAnger()
	print("🔄 DirectorMonitor: Recalibración forzada. Ira actual:", state.angerLevel)
end

-- ==================== INICIALIZACIÓN ====================
-- Conectar eventos básicos (opcional, puedes llamar manualmente desde otros scripts)
local function setupEventListeners()
	-- Escuchar muertes a través de DamageEvent
	local damageEvent = ReplicatedStorage:FindFirstChild("DamageEvent")
	if damageEvent then
		damageEvent.OnServerEvent:Connect(function(player, data)
			if data.action == "kill" then
				DirectorMonitor:onKill(player, data.target)
			end
		end)
	end

	-- Escuchar uso de poderes (si tienes un evento)
	local powerUsedEvent = ReplicatedStorage:FindFirstChild("PowerUsedEvent")
	if powerUsedEvent then
		powerUsedEvent.OnServerEvent:Connect(function(player)
			DirectorMonitor:onCypherUsed(player)
		end)
	end
end

-- Inicializar
state.lastRecalcTime = tick()
state.lastEventTime = tick()
setupEventListeners()

print("📊 DirectorMonitor BESTIA iniciado. Esperando carne...")

return DirectorMonitor
